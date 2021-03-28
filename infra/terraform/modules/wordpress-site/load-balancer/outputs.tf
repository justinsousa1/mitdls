output "lb" {
  value = aws_lb.webserver_lb
}

output "lb_dns_name" {
  value = aws_lb.webserver_lb.dns_name
}

output "lb_arn" {
  value = aws_lb.webserver_lb.arn
}

output "lb_arn_suffix" {
  value = aws_lb.webserver_lb.arn_suffix
}

output "lb_zone_id" {
  value = aws_lb.webserver_lb.zone_id
}

output "http_listener_arn" {
  value = aws_lb_listener.lb_http_listener.arn
}

output "https_listener_arn" {
  value = aws_lb_listener.lb_https_listener.arn
}

output "http_target_group_arn" {
  value = aws_lb_target_group.http_tg.arn
}

output "http_target_group_arn_suffix" {
  value = aws_lb_target_group.http_tg.arn_suffix
}

output "https_target_group_arn" {
  value = aws_lb_target_group.https_tg.arn
}

output "https_target_group_arn_suffix" {
  value = aws_lb_target_group.https_tg.arn_suffix
}

output "access_logs_bucket" {
  value = aws_s3_bucket.bucket_for_access_logs.bucket
}
