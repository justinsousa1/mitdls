variable "context" {
  description = "information about the context of the app/service"
  type = object({ environment_name=string, environment_type=string })
}

variable "additional_tags" {
  description = "additional tags that can be injected by the user/code instantiating the module. merged with default tags"
  type = map(string)
  default = {}
}

variable "vpc_id" {
  type = string
  default = "the vpc id to create the security groups in"
}