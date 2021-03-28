locals {
  context = {
    environment_type = "production"
    environment_name = "production"
  }
  root_domain = "production-wordpress.com"
  # this could also be pulled from remote state if the vpc is also managed by tf
  vpc_id = "vpc-prod12345"
  # across 3 different AZs
  subnet_ids = ["subnet1", "subnet2", "subnet3"]
}