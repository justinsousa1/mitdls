locals {
  http_port = 80
  https_port = 443
  app_name = "${var.context.environment_name}-wordpress"
  lb_name = "${local.app_name}-alb"

  access_log_bucket_name = "${local.lb_name}-access-logs"

  default_tags = {
    environment_name = var.context.environment_name
    environment_type = var.context.environment_type
    terraform_managed = "yes"
  }

  // see: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html
  elb_account_ids = {
    "us-east-1" = "127311923021"
    "us-east-2" = "033677994240"
  }
}

