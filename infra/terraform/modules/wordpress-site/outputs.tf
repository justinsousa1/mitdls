output "asg" {
  value = module.webserver_cluster.asg
}

output "asg_name" {
  value = module.webserver_cluster.asg_name
}

output "lb" {
  value = module.load_balancer.lb
}

output "lb_arn" {
  value = module.load_balancer.lb_arn
}

output "lb_arn_suffix" {
  value = module.load_balancer.lb_arn_suffix
}

output "asg_arn" {
  value = module.webserver_cluster.asg_arn
}

output "http_tg_arn_suffix" {
  value = module.load_balancer.http_target_group_arn_suffix
}

output "https_tg_arn_suffix" {
  value = module.load_balancer.https_target_group_arn_suffix
}

output "site_hostname" {
  value = "wordpress.${var.root_domain}"
}
