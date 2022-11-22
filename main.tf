terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 4.0"
        }
    }
}

provider "aws" {
    region = "us-east-1"
}

resource "aws_ssm_patch_baseline" "WINServers" {
    name = "WINServers_Patch-Baseline"
    description = "WIN 2012 and up server patches"
    operating_system = "WINDOWS"

    # Windows Critical and Security updates
    approval_rule {
        approve_after_days = 7
        patch_filter {
            key = "CLASSIFICATION"
            values = ["CriticalUpdates","SecurityUpdates"]
        }

    }

    # office 2010 patches
    approval_rule {
        approve_after_days = 7
        patch_filter {
            key = "PATCH_SET"
            values = ["APPLICATION"]
        }

        patch_filter {
            key = "PRODUCT"
            values = ["Office 2010"]
        }
    }
}

resource "aws_ssm_patch_group" "TestPatching" {
    baseline_id = aws_ssm_patch_baseline.WINServers.id
    patch_group = "TestPatching"
}

