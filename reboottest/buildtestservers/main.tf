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
  region = "us-east-1"
}

# data "terraform_remote_state" "kp" {
#   backend = "local"

#   config = {
#     path = "${path.module}/buildtestservers/keypair/terraform.tfstate"
#   }
# }

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_instance" "unica_servers" {
  count = 3

  ami                  = "ami-06371c9f2ad704460"
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.SSMInstanceProfile.name

  vpc_security_group_ids = [aws_security_group.instance.id]
  get_password_data      = true
  # key_name               = kp.name
  key_name = "InstanceKey"

  tags = {
    Name       = "AWS-UNICA-${count.index}"
    PatchGroup = "UNICAServers"
  }
}

resource "aws_security_group" "instance" {
  name = "Test-instance"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.instance.id

  from_port   = 0
  to_port     = 0
  protocol    = -1
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_rdp_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.instance.id

  from_port   = 3389
  to_port     = 3389
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_iam_role" "SSMManagedInstance_Role" {
  name = "SSMManagedInstance-Role"

  assume_role_policy = <<EOF
    {
      "Version" : "2012-10-17",
      "Statement" : {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "ec2.amazonaws.com",
            "ssm.amazonaws.com"
          ]
        }
      }
    }
  EOF

  #  assume_role_policy = jsonencode({
  #   Version = "2012-10-17"
  #   Statement = [
  #     {
  #       Action = "sts:AssumeRole"
  #       Effect = "Allow"
  #       Sid    = ""
  #       Principal = {
  #         Service = "ec2.amazonaws.com"
  #       }
  #     },
  #   ]
  # })

  # managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

  tags = {
    tag-key = "Deployed-Terraform"
  }
}

resource "aws_iam_instance_profile" "SSMInstanceProfile" {
  name = "SSM-Instance-Profile"
  role = aws_iam_role.SSMManagedInstance_Role.name
}

data "aws_iam_policy" "AmazonSSMManagedInstanceCore" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy" "AmazonSSMAutomationRole" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

# resource "aws_iam_role_policy_attachment" "SSMInstancePolicy" {
#   role       = aws_iam_role.SSMManagedInstance_Role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

resource "aws_iam_role_policy_attachment" "SSMInstancePolicy" {
  role = aws_iam_role.SSMManagedInstance_Role.name

  for_each = toset([
    data.aws_iam_policy.AmazonSSMManagedInstanceCore.arn,
    data.aws_iam_policy.AmazonSSMAutomationRole.arn
  ])

  policy_arn = each.key
}



