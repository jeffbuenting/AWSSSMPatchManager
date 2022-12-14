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

data "aws_instance" "Unica1" {
  filter {
    name   = "tag:Name"
    values = ["AWS-Unica-1"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instance" "Unica2" {
  filter {
    name   = "tag:Name"
    values = ["AWS-Unica-2"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

resource "aws_ssm_maintenance_window" "PatchandReboot" {
  name              = "Patch-and-reboot-two-servers"
  schedule          = var.cronjob
  schedule_timezone = "America/Chicago"
  duration          = 2
  cutoff            = 1
}

resource "aws_ssm_maintenance_window_target" "Unica_Servers" {
  name = "unica-servers"

  window_id     = aws_ssm_maintenance_window.PatchandReboot.id
  description   = "Targets Unica Servers"
  resource_type = "INSTANCE"

  targets {
    key    = "tag:PatchGroup"
    values = ["${var.patchgroup}"]
  }
}

resource "aws_ssm_maintenance_window_task" "Patch_Servers" {
  window_id       = aws_ssm_maintenance_window.PatchandReboot.id
  task_arn        = "AWS-RunPatchBaseline"
  task_type       = "RUN_COMMAND"
  priority        = 1
  max_concurrency = 5
  max_errors      = 1

  task_invocation_parameters {
    run_command_parameters {
      parameter {
        name   = "Operation"
        values = [var.operation]
      }

      parameter {
        name   = "RebootOption"
        values = ["NoReboot"]
      }

    }
  }

  targets {
    key    = "WindowTargetIds"
    values = [aws_ssm_maintenance_window_target.Unica_Servers.id]
  }
}

resource "aws_ssm_maintenance_window_task" "ShutDown_Unica2" {
  window_id = aws_ssm_maintenance_window.PatchandReboot.id
  task_arn  = "AWS-StopEC2Instance"
  task_type = "AUTOMATION"
  priority  = 100
  # max_concurrency = 1
  # max_errors      = 1

  task_invocation_parameters {
    automation_parameters {
      parameter {
        name   = "InstanceId"
        values = [data.aws_instance.Unica2.id]
      }

      parameter {
        name   = "AutomationAssumeRole"
        values = [var.SSMAutomationRole]
      }
    }
  }
}

resource "aws_ssm_maintenance_window_task" "Restart_Unica1_and_wait" {
  window_id = aws_ssm_maintenance_window.PatchandReboot.id
  task_arn  = "RebootServerandWait"
  task_type = "AUTOMATION"
  priority  = 200
  # max_concurrency = 1
  # max_errors      = 1

  task_invocation_parameters {
    automation_parameters {
      parameter {
        name   = "InstanceId"
        values = [data.aws_instance.Unica1.id]
      }

      parameter {
        name   = "AutomationAssumeRole"
        values = [var.SSMAutomationRole]
      }

      parameter {
        name   = "SleepDuration"
        values = [var.sleep_duration]
      }
    }
  }
}

resource "aws_ssm_maintenance_window_task" "Start_Unica2" {
  window_id = aws_ssm_maintenance_window.PatchandReboot.id
  task_arn  = "AWS-StartEC2Instance"
  task_type = "AUTOMATION"
  priority  = 300
  # max_concurrency = 1
  # max_errors      = 1

  task_invocation_parameters {
    automation_parameters {
      parameter {
        name   = "InstanceId"
        values = [data.aws_instance.Unica2.id]
      }

      parameter {
        name   = "AutomationAssumeRole"
        values = [var.SSMAutomationRole]
      }
    }
  }
}





