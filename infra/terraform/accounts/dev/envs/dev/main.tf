provider "aws" {
  region = "us-east-1"
  version = "~> 3.0"
  profile = "${local.context.environment_type}_us-east-1"
}

// aws profiles named after environment type which corresponds to account alias (dev = development account)