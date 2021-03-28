terraform {
  required_version = ">= 0.12, < 0.14"
}

provider "aws" {
  region = "us-east-1"
  version = "~> 3.0"
  profile = "prod_us-east-1"
}

terraform {
  backend "s3" {
    bucket = "some-statefiles-bucket"
    key = "terraform-states/prod/prod-wordpress-site.tfstate"
    dynamodb_table = "dynamodb-lock-table"
    region = "us-east-1"
    profile = "prod_us-east-1"
    encrypt = true
  }
}

data "terraform_remote_state" "some_remote_state" {
  backend = "s3"
  config = {
    bucket = "some-statefiles-bucket"
    key = "some/path/to/a/remotestatefile.tfstate"
    region = "us-east-1"
    profile = "prod_us-east-1"
    encrypt = true
  }
}

data "aws_ami" "wordpress_ami" {
  most_recent      = true
  name_regex       = "^wordpress-webserver"
  owners           = ["self"]

  filter {
    name   = "tag:some_filter_tag"
    values = ["some_value"]
  }
  // if AMI is built per environment add filter for that tag/name w/ the environment_name

}

module "wordpress_site" {
  source = "../../../../modules/wordpress-site"
  vpc_id = local.vpc_id
  subnet_ids = local.subnet_ids
  root_domain = local.root_domain
  context = local.context
  webserver_ami_id = data.aws_ami.wordpress_ami.image_id
  // if able to run > 1 webserver, expose the asg sizes and instance_type here
}
