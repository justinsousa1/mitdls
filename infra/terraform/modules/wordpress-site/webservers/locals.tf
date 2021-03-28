locals {
 name_prefix = "${var.context.environment_name}_wordpress-webserver"
  default_tags = {
    app_name = "wordpress-site"
    environment_name = var.context.environment_name
    environment_type = var.context.environment_type
  }
}