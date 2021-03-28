output "common_sg_id" {
  value = aws_security_group.common_rules.id
}

output "lb_sg_id" {
  value = aws_security_group.load_balancer_sg.id
}

output "webserver_sg_id" {
  value = aws_security_group.webserver_sg.id
}

output "efs_sg_id" {
  value = aws_security_group.efs_sg.id
}

