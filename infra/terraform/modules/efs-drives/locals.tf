locals {
  name_prefix = "${var.context.environment_name}-efs-static-files"
  default_tags = {
    environment_name = var.context.environment_name
    environment_type = var.context.environment_type
  }
}