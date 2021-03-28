terraform {
  required_version = ">= 0.12, < 0.14"
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "instance_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "webserver_iam_role" {
  name = "${local.name_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

# attach a default aws managed policy
resource "aws_iam_role_policy_attachment" "vpc_readonly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCReadOnlyAccess"
  role = aws_iam_role.webserver_iam_role.name
}

data "aws_iam_policy_document" "webserver_iam_policy" {
  statement {
    effect = "Allow"
    actions = ["ec2:CreateTags"]
    resources = ["arn:aws:ec2:*:*:instance/*"]
  }

  # if using SSM
  statement {
    effect = "Allow"
    actions = [
      "ssm:UpdateInstanceInformation",
      "ec2:DescribeInstanceStatus",
      "ec2messages:*"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:DescribeSecret", "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds", "secretsmanager:ListSecrets"
    ]
    # could also pass in a variable list of secrets here
    resources = [
    "arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:/wordpress/${var.context.environment_name}/db-connection-info",
    ]
  }
}

resource "aws_iam_policy" "webserver_iam_policy" {
  name        = "${local.name_prefix}-iam-policy"
  description = "Provides the permissions required by the wordpress webserver for ${var.context.environment_name}"
  policy      = data.aws_iam_policy_document.webserver_iam_policy.json
}


resource "aws_iam_role_policy_attachment" "webserver_policy_attachment" {
  policy_arn = aws_iam_policy.webserver_iam_policy.arn
  role = aws_iam_role.webserver_iam_role.name
}

resource "aws_iam_instance_profile" "webserver_instance_profile" {
  role = aws_iam_role.webserver_iam_role.name
  name = "${local.name_prefix}-instance-profile"
}

resource "aws_launch_template" "webserver_launch_template" {
  name = "${local.name_prefix}-asg-launch-template"

  image_id = var.webserver_ami_id
  instance_type = var.instance_type
  key_name = var.context.environment_type
  vpc_security_group_ids = var.security_group_ids

  update_default_version = true

  user_data = base64encode(templatefile("${path.module}/templates/cloud-init.yml.tpl",
    {
      environment_name = var.context.environment_name
    }
  ))

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.ebs_volume_size
      encrypted = var.encrypt_ebs_volume
      # could set kms key id here as well if not using default
      delete_on_termination = var.delete_ebs_volume_on_term
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge({
      Name = local.name_prefix,
      ami_id = var.webserver_ami_id
      autoscaled = "yes"
    }, local.default_tags, var.additional_tags)
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge({
      Name = local.name_prefix,
      ami = var.webserver_ami_id
      autoscaled = "yes"
    }, local.default_tags, var.additional_tags)
  }


  iam_instance_profile {
    arn = aws_iam_instance_profile.webserver_instance_profile.arn
  }

  monitoring {
    enabled = true
  }

  tags = merge({Name = "${local.name_prefix}-launch-template"}, local.default_tags, var.additional_tags)

}

resource "aws_autoscaling_group" "webserver_asg" {
  name = "${local.name_prefix}-asg"
  max_size = var.max_asg_size
  min_size = var.min_asg_size
  desired_capacity = var.desired_asg_capacity

  health_check_type = "ELB"
  target_group_arns = var.target_group_arns

  launch_template {
    version = "$Latest"
    id = aws_launch_template.webserver_launch_template.id
  }

  vpc_zone_identifier = var.subnet_ids

  tags = [
    map("key", "Name", "value", local.name_prefix, "propagate_at_launch", true),
    map("key", "environment_name", "value", var.context.environment_name, "propagate_at_launch", true),
    map("key", "environment_name", "value", var.context.environment_name, "propagate_at_launch", true)
  ]

}

resource "aws_autoscaling_lifecycle_hook" "webserver_asg_lifecycle_hook_term" {
  name                   = "${local.name_prefix}-asg-lifecycle-hook"
  autoscaling_group_name = aws_autoscaling_group.webserver_asg.name
  default_result         = "CONTINUE"
  # could make a var here but just hardcoding for demo
  heartbeat_timeout      = 60
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}

resource "aws_cloudwatch_event_rule" "webserver_cloudwatch_event_rule" {
  name  = "${local.name_prefix}-cloudwatch-term-event-rule"
  event_pattern = templatefile("${path.module}/templates/cloudwatch-event-pattern-term.json.tpl", { asg_name = aws_autoscaling_group.webserver_asg.name } )
}

data "aws_lambda_function" "some_lambda_to_trigger" {
  function_name = "some-function-to-trigger-on-asg-events"
}

resource "aws_cloudwatch_event_target" "cloudwatch_term_event_target" {
  rule = aws_cloudwatch_event_rule.webserver_cloudwatch_event_rule.name
  arn  = data.aws_lambda_function.some_lambda_to_trigger.arn
}

resource "aws_lambda_permission" "asg_allow_cloudwatch_to_invoke_lambda" {
  statement_id  = "${local.name_prefix}-ExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = "some-function-to-trigger-on-asg-events"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.webserver_cloudwatch_event_rule.arn
}
