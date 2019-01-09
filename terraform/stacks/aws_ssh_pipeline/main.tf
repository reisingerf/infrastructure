terraform {
  required_version = "~> 0.11.6"

  backend "s3" {
    # AWS access credentials are retrieved from env variables
    bucket         = "umccr-terraform-states"
    key            = "aws_pipeline/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  # AWS access credentials are retrieved from env variables
  region = "ap-southeast-2"
}

provider "vault" {}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_lambda_function" "notify_slack" {
  function_name = "${var.notify_slack_lambda_function_name}"
  qualifier     = ""
}

module "check_samplesheet_lambda" {
  # based on: https://github.com/claranet/terraform-aws-lambda
  source = "../../modules/lambda"

  function_name = "${var.stack_name}_check_samplesheet_lambda_${var.deploy_env}"
  description   = "Lambda to kick off the samplesheet check pipeline step."
  handler       = "check_samplesheet.lambda_handler"
  runtime       = "python3.6"
  timeout       = 6
  memory_size   = 128

  source_path = "${path.module}/lambdas/check_samplesheet.py"

  attach_policy = true
  policy        = "${aws_iam_policy.lambda.arn}"

  attach_vpc_config = true

  vpc_config = {
    subnet_ids         = "${data.aws_subnet_ids.private_subnets.ids}"
    security_group_ids = ["${aws_security_group.allow_ssh.id}"]
  }

  environment {
    variables {
      SCRIPT_PATH       = "${var.check_samplesheet_script_path}"
      LAMBDA_ENV        = "${var.deploy_env}"
      SLACK_LAMBDA_NAME = "${var.notify_slack_lambda_function_name}"
      JUMP_HOST         = "${var.jump_host}"
      JUMP_HOST_PORT    = "${var.jump_host_port}"
      JUMP_HOST_USER    = "${var.jump_host_user}"
      DEST_HOST         = "${var.dest_host}"
      DEST_HOST_PORT    = "${var.dest_host_port}"
      DEST_HOST_USER    = "${var.dest_host_user}"
    }
  }

  tags = {
    Environment = "${var.deploy_env}"
    Stack       = "${var.stack_name}"
    Service     = "${var.stack_name}_lambda"
  }
}

module "bcl2fastq_lambda" {
  # based on: https://github.com/claranet/terraform-aws-lambda
  source = "../../modules/lambda"

  function_name = "${var.stack_name}_bcl2fastq_lambda_${var.deploy_env}"
  description   = "Lambda to kick off the bcl2fastq pipeline step."
  handler       = "start_bcl2fastq.lambda_handler"
  runtime       = "python3.6"
  timeout       = 6
  memory_size   = 128

  source_path = "${path.module}/lambdas/start_bcl2fastq.py"

  attach_policy = true
  policy        = "${aws_iam_policy.lambda.arn}"

  attach_vpc_config = true

  vpc_config = {
    subnet_ids         = "${data.aws_subnet_ids.private_subnets.ids}"
    security_group_ids = ["${aws_security_group.allow_ssh.id}"]
  }

  environment {
    variables {
      SCRIPT_PATH       = "${var.check_samplesheet_script_path}"
      LAMBDA_ENV        = "${var.deploy_env}"
      SLACK_LAMBDA_NAME = "${var.notify_slack_lambda_function_name}"
      JUMP_HOST         = "${var.jump_host}"
      JUMP_HOST_PORT    = "${var.jump_host_port}"
      JUMP_HOST_USER    = "${var.jump_host_user}"
      DEST_HOST         = "${var.dest_host}"
      DEST_HOST_PORT    = "${var.dest_host_port}"
      DEST_HOST_USER    = "${var.dest_host_user}"
    }
  }

  tags = {
    Environment = "${var.deploy_env}"
    Stack       = "${var.stack_name}"
    Service     = "${var.stack_name}_lambda"
  }
}

data "archive_file" "lib_package" {
  # Temporary solution to create a lambda layer package
  # Manually deploy with AWSCLI:
  #  aws --profile umccr_ops_admin_no_mfa lambda publish-layer-version --layer-name aws_pipeline_libs --description "Python libraries required for the pipeline lambdas" --zip-file fileb://aws_pipeline_libs.zip --compatible-runtimes python3.6 python3.7
  # Then manually link the layer to the lambda in the AWS console
  # TODO: replace with Terraform solution once available
  type = "zip"

  source_dir  = "${path.module}/lambdas/lib"
  output_path = "${path.module}/lambdas/aws_pipeline_libs.zip"
}

data "template_file" "lambda" {
  template = "${file("${path.module}/policies/check-samplesheet-lambda.json")}"

  vars {
    lambda_arn          = "${data.aws_lambda_function.notify_slack.arn}"
    novastor_secret_arn = "${data.aws_secretsmanager_secret.novastor.arn}"
  }
}

resource "aws_iam_policy" "lambda" {
  name   = "${var.stack_name}_lambda_${var.deploy_env}"
  path   = "/${var.stack_name}/"
  policy = "${data.template_file.lambda.rendered}"
}

data "aws_secretsmanager_secret" "novastor" {
  name = "dev/aws_pipeline/novastor"
}

data "aws_vpc" "vpc" {
  tags = {
    Environment = "${var.deploy_env}"
    Stack       = "bootstrap"
    Name        = "vpc-bootstrap-main"
  }
}

data "aws_subnet_ids" "private_subnets" {
  vpc_id = "${data.aws_vpc.vpc.id}"

  tags = {
    SubnetType = "private_app"
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH traffic"
  vpc_id      = "${data.aws_vpc.vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "allow_ssh"
    Stack       = "${var.stack_name}"
    Environment = "${var.deploy_env}"
  }
}
