variable "context" {
  description = "information about the context of the app/service"
  type = object({ environment_name=string, environment_type=string })
}

variable "additional_tags" {
  type = map(string)
  default = {}
}

variable "encrypt_drives" {
  type = bool
}


variable "performance_mode" {
  type = string
  default = "maxIO"
}

variable "transition_to_ia_setting" {
  type = string
  default = "AFTER_60_DAYS"
}

variable "subnet_ids" {
  type = list(string)
  description = "subnets for EFS interfaces"
}

variable "security_groups_for_efs_mount" {
  type = list(string)
}