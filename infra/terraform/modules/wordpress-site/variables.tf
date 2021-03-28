variable "root_domain" {
  type = string
  description = "the root domain that the site is hosted on (route53 zone created elsewhere)"
}

variable "context" {
  description = "information about the context of the app/service"
  type = object({ environment_name=string, environment_type=string })
}

variable "vpc_id" {
  type = string
  description = "the vpc id that the site should be deployed to"
}

variable "subnet_ids" {
  type = list(string)
}

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "webserver_ami_id" {
  type = string
}
