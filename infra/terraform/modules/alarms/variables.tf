variable "context" {
  description = "information about the context of the app/service"
  type = object({ environment_name=string, environment_type=string })
}

variable "load_balancer_arn_suffix" {}
variable "target_group_arn_suffix" {}

variable "alert_sns_topic_arn" {}
