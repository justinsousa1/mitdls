locals {
  context = {
    environment_type = "staging"
    environment_name = "staging"
  }
  root_domain = "staging-wordpress.com"
  # this could also be pulled from remote state if the vpc is also managed by tf
  vpc_id = "vpc-staging12345"
  # across 3 different AZs
  subnet_ids = ["subnet1", "subnet2", "subnet3"]
}