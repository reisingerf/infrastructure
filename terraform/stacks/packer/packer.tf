terraform {
  backend "s3" {
    bucket  = "umccr-terraform-prod"
    key     = "packer/terraform.tfstate"
    region  = "ap-southeast-2"
  }
}

provider "aws" {
  region  = "${var.aws_region}"
}


resource "aws_iam_role" "packer_role" {
  name               = "packer_role"
  path               = "/"
  assume_role_policy = "${file("policies/assume_packer_role.json")}"
}

resource "aws_iam_instance_profile" "new_packer_instance_profile" {
  name  = "new_packer_instance_profile"
  role = "${aws_iam_role.packer_role.name}"
}


resource "aws_iam_policy" "packer_ec2" {
  name   = "packer_ec2"
  path   = "/"
  policy = "${file("policies/packer_ec2.json")}"
}

resource "aws_iam_policy_attachment" "packer_ec2_policy_to_packer_role_attachment" {
    name       = "packer_ec2_policy_to_packer_role_attachment"
    policy_arn = "${aws_iam_policy.packer_ec2.arn}"
    groups     = []
    users      = []
    roles      = [ "${aws_iam_role.packer_role.name}" ]
}