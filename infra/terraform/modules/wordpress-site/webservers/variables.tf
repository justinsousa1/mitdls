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
  description = "the vpc to deploy the asg into"
}

variable "subnet_ids" {
  type = list(string)
  description = "the subnets that webservers can be deployed into. assigned to the launch tmeplate"
}

variable "security_group_ids" {
  type = list(string)
  description = "the security groups to assign to the webservers via the launch template"
}

variable "webserver_ami_id" {
  description = "the ami to use to launch the webservers, instantiation of the module should define this and pass in "
}

variable "instance_type" {
  default = "t2.medium"
}

variable "ebs_volume_size" {
  description = "size of ebs volume mounted to the instance via asg launch template in GB"
  default = 25
}

variable "encrypt_ebs_volume" {
  type = bool
  default = true
  description = "if true, ebs volume attached will be encrypted"
}

variable "delete_ebs_volume_on_term" {
  type = bool
  default = true
  description = <<EOF
whether to delete the ebs volumes attached to the instances in the asg when instances are termed.
In general, all storage that you care about should likely be stored either in s3 or an EFS drive OR an dedicated
EBS volume that gets attached. IO performance factors in to the decision as well
EOF
}

# for demo here just use instance capacity of 1 and use ASG just for the convenience of keeping instance running
variable "min_asg_size" {
  description = "webserver autoscaling group min size"
  default = 1
}

variable "max_asg_size" {
  description = "webserver autoscaling group max size"
  default = 1
}

variable "desired_asg_capacity" {
  default = 1
}

variable "target_group_arns" {
  description = "the alb/elb target groups that these instances will be registered with"
}
