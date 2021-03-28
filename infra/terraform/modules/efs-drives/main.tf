resource "aws_efs_file_system" "static_files_drive" {
  creation_token = "${local.name_prefix}_drive"

  encrypted = var.encrypt_drives

  tags = merge(
  {
    Name = "${local.name_prefix}-drive"
    efs_purpose = "static-files"
  }, local.default_tags)

  lifecycle_policy {
    transition_to_ia = var.transition_to_ia_setting
  }

  performance_mode = var.performance_mode
}

resource "aws_efs_mount_target" "efs_mount_targets" {
  count = length(var.subnet_ids)
  file_system_id = aws_efs_file_system.static_files_drive.id
  subnet_id = element(var.subnet_ids, count.index)
  security_groups = var.security_groups_for_efs_mount
}


resource "aws_backup_vault" "static_files_backup_vault" {
  name = "${local.name_prefix}_backup-vault"

  tags = merge({
    Name = "${local.name_prefix}_backup-vault"
  },local.default_tags)
}


resource "aws_backup_plan" "static_files_backup_plan" {
  name = "${local.name_prefix}_backup-plan"

  rule {
    rule_name         = "${local.name_prefix}_backup-rule"
    target_vault_name = aws_backup_vault.static_files_backup_vault.name
    schedule          = "cron(0 5 * * ? *)" # time is in UTC
    lifecycle {
      delete_after = 7
    }
  }

  tags = merge({
    Name = "${local.name_prefix}_backup-plan"
  },local.default_tags)
}

data "aws_iam_policy_document" "assume_backup" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["backup.amazonaws.com"]
      type = "Service"
    }
  }
}

resource "aws_iam_role" "static_files_backup_iam_role" {
  name               = "${local.name_prefix}_backup-role"
  assume_role_policy = data.aws_iam_policy_document.assume_backup.json
}

data "aws_iam_policy_document" "static_files_backup_iam_policy" {
  statement {
    actions = ["elasticfilesystem:Backup"]
    resources = [
      aws_efs_file_system.static_files_drive.arn,
    ]
  }

  statement {
    actions = ["backup:CopyIntoBackupVault"]
    resources = [aws_backup_vault.static_files_backup_vault.arn]
  }
}

resource "aws_iam_policy" "static_files_backup_iam_policy" {
  name        = "${local.name_prefix}_backup-policy"
  description = "Provides the permissions required to backup static files efs drive"
  policy      = data.aws_iam_policy_document.static_files_backup_iam_policy.json
}

resource "aws_iam_role_policy_attachment" "static_files_backup_iam_policy_attachment" {
  role       = aws_iam_role.static_files_backup_iam_role.name
  policy_arn = aws_iam_policy.static_files_backup_iam_policy.arn
}

resource "aws_backup_selection" "static_files_backup_selection" {
  name         = "${local.name_prefix}_backup-selection"
  iam_role_arn = aws_iam_role.static_files_backup_iam_role.arn
  plan_id      = aws_backup_plan.static_files_backup_plan.id
  resources = [
    aws_efs_file_system.static_files_drive.arn
  ]
}
