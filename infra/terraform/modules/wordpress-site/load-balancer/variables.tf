variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "lb_subnet_ids" {
  description = "the subnet ids for the alb"
  type = list(string)
}

variable "lb_security_group_id" {
  description = "the security group to apply to the load balancers"
  type = string
}

variable "context" {
  description = "information about the context of the app/service"
  type = object({ environment_name=string, environment_type=string })
}


variable "root_domain" {
  type = string
  description = "domain for the ACM cert and route53 zone"
}

variable "acm_cert_type" {
  default = "AMAZON_ISSUED"
  type = string
}

variable "additional_tags" {
  type = map(string)
  default = {}
}