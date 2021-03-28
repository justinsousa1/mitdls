data "aws_caller_identity" "current" {}

locals {
  site_hostname = "$wordpress.${var.root_domain}"
}
