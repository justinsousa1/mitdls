output "asg" {
  value = aws_autoscaling_group.webserver_asg
}

output "asg_name" {
  value = aws_autoscaling_group.webserver_asg.name
}

output "asg_arn" {
  value = aws_autoscaling_group.webserver_asg.arn
}

output "launch_template_id" {
  value = aws_launch_template.webserver_launch_template.id
}

output "launch_template_arn" {
  value = aws_launch_template.webserver_launch_template.arn
}
