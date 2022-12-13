# separating this from the SSM resources to similate real world

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "instance" {
  source = "github.com/jeffbuenting/TF_Module_EC2_Instance"

  num_instances = 3
  ami           = "ami-06371c9f2ad704460"
  instance_type = "t2.micro"
  private_key   = "C:/Users/kwbre/Downloads/InstanceKey.pem"
  instance_name = "AWS-Unica"
  patchgroup    = "UnicaServers"
  kp_name       = "InstanceKey"
}
