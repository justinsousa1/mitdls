terraform {
  required_version = ">= 0.12, < 0.14"
}

data "aws_caller_identity" "current" {}

data "aws_acm_certificate" "load_balancer_cert" {
  domain = "*.${var.root_domain}"
  statuses = ["ISSUED"]
  types = [var.acm_cert_type]
  most_recent = true
}

resource "aws_lb" "webserver_lb" {
  name = local.lb_name
  load_balancer_type = "application"
  subnets = var.lb_subnet_ids
  security_groups = [var.lb_security_group_id]

  access_logs {
    bucket = aws_s3_bucket.bucket_for_access_logs.bucket
    prefix = local.lb_name
    enabled = true
  }

  tags = merge(
  {
    Name  = local.lb_name
  },
  local.default_tags,
  var.additional_tags
  )

  idle_timeout = 60

}

# redirect http to https by default
resource "aws_lb_listener" "lb_http_listener" {
  load_balancer_arn = aws_lb.webserver_lb.arn
  port = local.http_port
  protocol = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port = local.https_port
      protocol = "HTTPS"
      status_code = "HTTP_301"
      host = "#{host}"
      path = "/#{path}"
      query = "#{query}"
    }
  }
}

resource "aws_lb_listener" "lb_https_listener" {
  load_balancer_arn = aws_lb.webserver_lb.arn
  port = local.https_port
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn = data.aws_acm_certificate.load_balancer_cert.arn

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "http_tg" {
  name = "${local.lb_name}-http"
  port = local.http_port
  protocol = "HTTP"
  vpc_id = var.vpc_id
  target_type = "instance"

  health_check {
    port = local.http_port
    path = "/"
  }
  tags = merge({
    Name  = "${local.lb_name}-http"
  })
}

resource "aws_lb_target_group" "https_tg" {
  name = "${local.lb_name}-https"
  port = local.https_port
  protocol = "HTTPS"
  vpc_id = var.vpc_id
  target_type = "instance"

  health_check {
    port = local.http_port
    path = "/"
  }
  tags = merge({
    Name  = "${local.lb_name}-https"
  })
}

resource "aws_lb_listener_rule" "forward_http_rule" {
  listener_arn = aws_lb_listener.lb_http_listener.arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.http_tg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

resource "aws_lb_listener_rule" "forward_https_rule" {
  listener_arn = aws_lb_listener.lb_https_listener.arn
  priority = 100

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.https_tg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

data template_file "bucket_policy" {
  template = file("${path.module}/templates/bucket_policy.json.tpl")
  vars = {
    elb_account_id = local.elb_account_ids[var.aws_region]
    account_id = data.aws_caller_identity.current.account_id
    bucket_name = local.access_log_bucket_name
    prefix = local.lb_name
  }
}

resource "aws_s3_bucket" "bucket_for_access_logs" {
  bucket = local.access_log_bucket_name
  policy = data.template_file.bucket_policy.rendered
  acl = "log-delivery-write"
  tags = merge(local.default_tags, var.additional_tags)

  region = var.aws_region

  lifecycle_rule {
    id = "log"
    prefix = local.lb_name
    enabled = true

    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days = 60
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }

}

resource "aws_s3_bucket_public_access_block" "access_logs_block_public_acls" {
  bucket = aws_s3_bucket.bucket_for_access_logs.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
