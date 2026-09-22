terraform {
  source = "../../modules/calculator-batch"
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "terraform-state-dev-511531632788-us-west-1"
    key            = "calculator-batch/terraform.tfstate"
    region         = "us-west-1"
    encrypt        = true
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "us-west-1"
}
EOF
}
