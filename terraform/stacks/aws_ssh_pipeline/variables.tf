variable "stack_name" {
  default = "aws_pipeline"
}

variable "deploy_env" {
  description = "The deployment environment against which to deploy this stack. Select either 'dev' or 'prod'."
}

variable "notify_slack_lambda_function_name" {
  description = "Name of the Slack notification Lambda"
}

################################################################################
# SSH parameter

variable "dest_host" {
  description = "The host to use as a SSH dest host."
}

variable "dest_host_port" {
  description = "The SSH port to use for the dest host."
}

variable "dest_host_user" {
  description = "The SSH user to use for the dest host."
}

variable "jump_host" {
  description = "The host to use as a SSH jump host."
}

variable "jump_host_port" {
  description = "The SSH port to use for the jump host."
}

variable "jump_host_user" {
  description = "The SSH user to use for the jump host."
}

################################################################################
# Script paths for scripts of the pipeline

variable "check_samplesheet_script_path" {
  description = "The full path of the samplesheet check script."
}

variable "start_bcl2fastq_script_path" {
  description = "The full path of the samplesheet check script."
}
