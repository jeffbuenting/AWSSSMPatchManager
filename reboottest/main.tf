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

data "aws_instance" "Unica1" {
  filter {
    name   = "tag:Name"
    values = ["AWS-UNICA-1"]
  }

  filter {
    name   = "instance-state-name"
    values = ["running"]
  }
}

data "aws_instance" "Unica2" {
  filter {
    name   = "tag:Name"
    values = ["AWS-UNICA-2"]
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
    values = ["UNICAServers"]
  }
}

# because a task with multiple targets runs sequentially, a separate task for each target should be created to run parallel
# https://docs.amazonaws.cn/en_us/systems-manager/latest/userguide/sysman-maintenance-assign-targets.html

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
        name   = "operation"
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

# resource "aws_ssm_maintenance_window_task" "Patch_Server2" {
#   window_id       = aws_ssm_maintenance_window.PatchandReboot.id
#   task_arn        = "AWS-RunPatchBaseline"
#   task_type       = "RUN_COMMAND"
#   priority        = 1
#   max_concurrency = 5
#   max_errors      = 1

#   task_invocation_parameters {
#     run_command_parameters {
#       parameter {
#         name   = "operation"
#         values = [var.operation]
#       }

#       parameter {
#         name   = "rebootoption"
#         values = ["NoReboot"]
#       }
#     }
#   }

#   targets {
#     key    = "InstanceIds"
#     values = [data.aws_instance.Unica2.id]
#   }
# }

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

resource "aws_ssm_maintenance_window_task" "Restart_Unica1" {
  window_id = aws_ssm_maintenance_window.PatchandReboot.id
  task_arn  = "AWS-RestartEC2Instance"
  task_type = "AUTOMATION"
  priority  = 100
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
    }
  }
}

resource "aws_ssm_maintenance_window_task" "Wait_X_Minutes" {
  window_id = aws_ssm_maintenance_window.PatchandReboot.id
  task_arn  = "AWA_Sleep"
  task_type = "AUTOMATION"
  priority  = 200

  task_invocation_parameters {
    automation_parameters {
      parameter {
        name   = "Duration"
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




