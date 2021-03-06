terraform {
  required_version = "~> 0.11.6"

  backend "s3" {
    # AWS access credentials are retrieved from env variables
    bucket         = "umccr-terraform-states"
    key            = "stackstorm/terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  # AWS access credentials are retrieved from env variables
  region = "ap-southeast-2"
}

provider "vault" {
  # Vault server address and access token are retrieved from env variables (VAULT_ADDR and VAULT_TOKEN)
}

data "vault_generic_secret" "datadog" {
  path = "kv/datadog"
}

module "stackstorm" {
  # NOTE: the source cannot be interpolated, so we can't use a variable here and have to keep the difference bwtween production and developmment in a branch
  source                        = "git::git@github.com:umccr/infrastructure.git//terraform/modules/stackstorm?ref=0.1.3"
  instance_type                 = "t2.small"
  instance_spot_price           = "0.018"
  use_spot                      = false
  availability_zone             = "ap-southeast-2a"
  name_suffix                   = "${terraform.workspace}"
  stack_name                    = "${var.stack_name}"
  root_domain                   = "${var.workspace_zone_domain[terraform.workspace]}"
  stackstorm_sub_domain         = "${var.stack_name}"
  stackstorm_data_volume_name   = "${var.workspace_st_data_volume[terraform.workspace]}"    # NOTE: volume must exist
  stackstorm_docker_volume_name = "${var.workspace_st_docker_volume[terraform.workspace]}"  # NOTE: volume must exist
  st2_hostname                  = "${var.workspace_dd_hostname[terraform.workspace]}"
  datadog_apikey                = "${data.vault_generic_secret.datadog.data["api-key"]}"
  instance_tags                 = "${var.workspace_st2_instance_tags[terraform.workspace]}"

  # ami_filters                   = "${var.ami_filters}" # can be used to overwrite the default AMI lookup
}
