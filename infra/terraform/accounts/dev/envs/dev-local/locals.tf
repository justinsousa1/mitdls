locals {
  # trim whitespace and non safe characters for most resources
  namespace = replace(trimspace(var.workspace_name), "/\\W/", "")
  context = {
    environment_type = "dev"
    environment_name = "dev${local.namespace}"
  }
}