variable "vault_instance_type" {
  default = "t2.micro"
}

variable "vault_availability_zone" {
  default = "ap-southeast-2a"
}

variable "vault_sub_domain" {
  default = "vault"
}

################################################################################
## workspace variables

variable "workspace_name_suffix" {
  default = {
    prod = "_prod"
    dev  = "_dev"
  }
}

variable "workspace_vault_bucket_name" {
  default = {
    prod = "umccr-vault-data-prod"
    dev  = "umccr-vault-data-dev"
  }
}

variable "workspace_root_domain" {
  default = {
    prod = "prod.umccr.org"
    dev  = "dev.umccr.org"
  }
}