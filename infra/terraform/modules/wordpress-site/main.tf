terraform {
  required_version = ">= 0.12, < 0.14"
}

data "aws_route53_zone" "public_domain" {
  name = var.root_domain
  private_zone = false
}

module "security_groups" {
  source = "./security_groups"
  context = var.context
  vpc_id = var.vpc_id
}

module "efs_drives" {
  source = "../efs-drives"
  context = var.context
  encrypt_drives = true
  subnet_ids = var.subnet_ids
  security_groups_for_efs_mount = module.security_groups.efs_sg_id
}


module "waf" {
  source = "./waf"
  context = var.context
}

module "load_balancer" {
  source = "./load-balancer"
  context = var.context
  aws_region = var.aws_region
  vpc_id = var.vpc_id
  lb_subnet_ids = var.subnet_ids
  root_domain = var.root_domain
  lb_security_group_id = module.security_groups.lb_sg_id
}

module "webserver_cluster" {
  source = "./webservers"
  context = var.context

  vpc_id = var.vpc_id
  subnet_ids = var.subnet_ids
  security_group_ids = [module.security_groups.webserver_sg_id]

  webserver_ami_id = var.webserver_ami_id

  target_group_arns = [
    module.load_balancer.http_target_group_arn, module.load_balancer.https_target_group_arn
  ]
}

// more traditional CNAME record

//resource "aws_route53_record" "cname_record" {
//  zone_id = data.aws_route53_zone.public_domain.zone_id
//  name    = local.site_hostname
//  type    = "CNAME"
//  ttl     = 60
//  records        = [module.load_balancer.lb_dns_name]
//}

resource "aws_route53_record" "alias_record" {
  zone_id = data.aws_route53_zone.public_domain.zone_id
  name    = local.site_hostname
  type    = "A"

  alias {
    name                   = module.load_balancer.lb_dns_name
    zone_id                = module.load_balancer.lb_zone_id
    evaluate_target_health = true
  }

}
