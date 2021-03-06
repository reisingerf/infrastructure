variable "availability_zone" {
  default = "ap-southeast-2c"
}

variable "umccrise_image_id" {
  default = "ami-03037fc9d9ca37131"
}

variable "stack_name" {
  default = "umccrise"
}

################################################################################
## workspace variables

variable "workspace_slack_lambda_arn" {
  type = "map"

  default = {
    prod = "arn:aws:lambda:ap-southeast-2:472057503814:function:bootstrap_slack_lambda_prod"
    dev  = "arn:aws:lambda:ap-southeast-2:620123204273:function:bootstrap_slack_lambda_dev"
  }
}

variable "workspace_umccrise_data_bucket" {
  type = "map"

  default = {
    prod = "umccr-primary-data-prod"
    dev  = "umccr-primary-data-dev"
  }
}

variable "workspace_umccrise_refdata_bucket" {
  type = "map"

  default = {
    prod = "umccr-umccrise-refdata-prod"
    dev  = "umccr-umccrise-refdata-dev"
  }
}

variable "workspace_umccrise_buckets" {
  type = "map"

  default = {
    prod = ["arn:aws:s3:::umccr-primary-data-prod", "arn:aws:s3:::umccr-primary-data-prod/*", "arn:aws:s3:::umccr-umccrise-prod", "arn:aws:s3:::umccr-umccrise-prod/*", "arn:aws:s3:::umccr-umccrise-refdata-prod", "arn:aws:s3:::umccr-umccrise-refdata-prod/*"]
    dev  = ["arn:aws:s3:::umccr-primary-data-dev", "arn:aws:s3:::umccr-primary-data-dev/*", "arn:aws:s3:::umccr-umccrise-dev", "arn:aws:s3:::umccr-umccrise-dev/*", "arn:aws:s3:::umccr-umccrise-refdata-dev", "arn:aws:s3:::umccr-umccrise-refdata-dev/*"]
  }
}
