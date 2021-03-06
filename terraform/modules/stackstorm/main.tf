resource "aws_iam_role" "stackstorm_role" {
  name               = "${var.stack_name}_${var.name_suffix}"
  path               = "/${var.stack_name}/"
  assume_role_policy = "${data.aws_iam_policy_document.stackstorm_assume_policy.json}"
}
data "aws_iam_policy_document" "stackstorm_assume_policy" {
  statement {
    actions = [ "sts:AssumeRole" ]

    principals {
      type        = "Service"
      identifiers = [ "ec2.amazonaws.com" ]
    }
  }
}

resource "aws_iam_instance_profile" "stackstorm_instance_profile" {
  role = "${aws_iam_role.stackstorm_role.name}"
}


resource "aws_iam_policy" "s3_stackstorm_policy" {
  name   = "${var.stack_name}_s3_policy_${var.name_suffix}"
  path   = "/${var.stack_name}/"
  policy = "${file("${path.module}/policies/s3_stackstorm_policy.json")}"
}
resource "aws_iam_role_policy_attachment" "s3_policy_to_stackstorm_role_attachment" {
  role       = "${aws_iam_role.stackstorm_role.name}"
  policy_arn = "${aws_iam_policy.s3_stackstorm_policy.arn}"
}


resource "aws_iam_policy" "ec2_stackstorm_policy" {
  name   = "${var.stack_name}_ec2_policy_${var.name_suffix}"
  path   = "/${var.stack_name}/"
  policy = "${file("${path.module}/policies/ec2_stackstorm_policy.json")}"
}
resource "aws_iam_role_policy_attachment" "ec2_policy_to_stackstorm_role_attachment" {
    role       = "${aws_iam_role.stackstorm_role.name}"
    policy_arn = "${aws_iam_policy.ec2_stackstorm_policy.arn}"
}

resource "aws_iam_policy" "iam_stackstorm_policy" {
  name   = "${var.stack_name}_iam_policy_${var.name_suffix}"
  path   = "/${var.stack_name}/"
  policy = "${file("${path.module}/policies/iam_stackstorm_policy.json")}"
}
resource "aws_iam_role_policy_attachment" "iam_policy_to_stackstorm_role_attachment" {
    role       = "${aws_iam_role.stackstorm_role.name}"
    policy_arn = "${aws_iam_policy.iam_stackstorm_policy.arn}"
}

resource "aws_iam_policy" "spot_stackstorm_policy" {
  name   = "${var.stack_name}_spot_policy_${var.name_suffix}"
  path   = "/${var.stack_name}/"
  policy = "${file("${path.module}/policies/AmazonEC2SpotFleetTaggingRole.json")}"
}
resource "aws_iam_role_policy_attachment" "spot_policy_to_stackstorm_role_attachment" {
    role       = "${aws_iam_role.stackstorm_role.name}"
    policy_arn = "${aws_iam_policy.spot_stackstorm_policy.arn}"
}


data "aws_ami" "stackstorm_ami" {
  most_recent      = true
  owners           = [ "620123204273" ]
  executable_users = [ "self" ]
  name_regex = "^stackstorm-ami*"
}


resource "aws_instance" "stackstorm_instance" {
  count = "${var.use_spot ? 0 : 1}"

  ami                    = "${data.aws_ami.stackstorm_ami.id}"
  instance_type          = "${var.instance_type}"
  availability_zone      = "${var.availability_zone}"
  iam_instance_profile   = "${aws_iam_instance_profile.stackstorm_instance_profile.id}"
  subnet_id              = "${aws_subnet.sn_a_vpc_st2.id}"
  vpc_security_group_ids = [ "${aws_security_group.vpc_st2.id}" ]
  monitoring             = true
  user_data              = "${data.template_file.lc_userdata.rendered}"

  root_block_device {
      volume_type           = "gp2"
      volume_size           = 10
      delete_on_termination = true
  }

  tags {
    Name = "${var.stack_name}-${var.name_suffix}"
  }
}

resource "aws_spot_instance_request" "stackstorm_instance" {
  count = "${var.use_spot ? 1 : 0}"

  spot_price             = "${var.instance_spot_price}"
  wait_for_fulfillment   = true

  ami                    = "${data.aws_ami.stackstorm_ami.id}"
  instance_type          = "${var.instance_type}"
  availability_zone      = "${var.availability_zone}"
  iam_instance_profile   = "${aws_iam_instance_profile.stackstorm_instance_profile.id}"
  subnet_id              = "${aws_subnet.sn_a_vpc_st2.id}"
  vpc_security_group_ids = [ "${aws_security_group.vpc_st2.id}" ]

  instance_interruption_behaviour = "stop"
  monitoring             = true
  user_data              = "${data.template_file.lc_userdata.rendered}"

  root_block_device {
      volume_type           = "gp2"
      volume_size           = 10
      delete_on_termination = true
  }

  # tags apply to the spot request, NOT the instance!
  # https://github.com/terraform-providers/terraform-provider-aws/issues/174
  # https://github.com/hashicorp/terraform/issues/3263#issuecomment-284387578
  tags {
    Name = "${var.stack_name}-${var.name_suffix}"
  }
}

data "template_file" "lc_userdata" {
    template = "${file("${path.module}/template-files/lc-userdata.tpl")}"
    vars {
        allocation_id  = "${aws_eip.stackstorm.id}"
        st2_hostname   = "${var.st2_hostname}"
        datadog_apikey = "${var.datadog_apikey}"
        instance_tags = "${jsonencode(var.instance_tags)}"
    }
}

data "aws_ebs_volume" "stackstorm_data_volume" {
  most_recent = true

  filter {
    name   = "volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.stackstorm_data_volume_name}"]
  }
}

data "aws_ebs_volume" "stackstorm_docker_volume" {
  most_recent = true

  filter {
    name   = "volume-type"
    values = ["gp2"]
  }

  filter {
    name   = "tag:Name"
    values = ["${var.stackstorm_docker_volume_name}"]
  }
}

resource "aws_volume_attachment" "ebs_att_st2_data" {
  count = "${var.use_spot ? 0 : 1}"
  device_name  = "/dev/sdf"
  volume_id    = "${data.aws_ebs_volume.stackstorm_data_volume.id}"
  instance_id  = "${aws_instance.stackstorm_instance.id}"
  skip_destroy = true # needed, since we are using an externally maintained EBS volume
}

resource "aws_volume_attachment" "ebs_att_st2_docker" {
  count = "${var.use_spot ? 0 : 1}"
  device_name  = "/dev/sdg"
  volume_id    = "${data.aws_ebs_volume.stackstorm_docker_volume.id}"
  instance_id  = "${aws_instance.stackstorm_instance.id}"
  skip_destroy = true # needed, since we are using an externally maintained EBS volume
}


resource "aws_volume_attachment" "ebs_att_st2_data_spot" {
  count = "${var.use_spot ? 1 : 0}"
  device_name  = "/dev/sdf"
  volume_id    = "${data.aws_ebs_volume.stackstorm_data_volume.id}"
  instance_id  = "${aws_spot_instance_request.stackstorm_instance.spot_instance_id}"
  skip_destroy = true # needed, since we are using an externally maintained EBS volume
}

resource "aws_volume_attachment" "ebs_att_st2_docker_spot" {
  count = "${var.use_spot ? 1 : 0}"
  device_name  = "/dev/sdg"
  volume_id    = "${data.aws_ebs_volume.stackstorm_docker_volume.id}"
  instance_id  = "${aws_spot_instance_request.stackstorm_instance.spot_instance_id}"
  skip_destroy = true # needed, since we are using an externally maintained EBS volume
}

resource "aws_eip" "stackstorm" {
  vpc         = true
  depends_on  = ["aws_internet_gateway.vpc_st2"]
}

data "aws_route53_zone" "umccr_org" {
  name         = "${var.root_domain}."
}

resource "aws_route53_record" "st2_prod" {
  # TODO: the domain should depend on the account the stack is deployed against!
  zone_id = "${data.aws_route53_zone.umccr_org.zone_id}"
  name    = "${var.stackstorm_sub_domain}.${data.aws_route53_zone.umccr_org.name}"
  type    = "A"
  ttl     = "300"
  records = ["${aws_eip.stackstorm.public_ip}"]
}

resource "aws_vpc" "vpc_st2" {
    cidr_block           = "172.31.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support   = true
    instance_tenancy     = "default"

    tags {
      Name = "${var.stack_name}_vpc_${var.name_suffix}"
    }
}

resource "aws_subnet" "sn_a_vpc_st2" {
    vpc_id                  = "${aws_vpc.vpc_st2.id}"
    cidr_block              = "172.31.0.0/20"
    map_public_ip_on_launch = true
    availability_zone       = "${var.availability_zone}"

    tags {
      Name = "${var.stack_name}_subnet_a_${var.name_suffix}"
    }
}

resource "aws_internet_gateway" "vpc_st2" {
  vpc_id = "${aws_vpc.vpc_st2.id}"

  tags {
    Name = "${var.stack_name}_internet_gateway_${var.name_suffix}"
  }
}

resource "aws_route_table" "st2_rt" {
  vpc_id = "${aws_vpc.vpc_st2.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.vpc_st2.id}"
  }
}

# TODO: check if we need to associate the route table to the subnet or if it automatically applies to the wholw vpc
resource "aws_route_table_association" "st2_rt" {
  subnet_id = "${aws_subnet.sn_a_vpc_st2.id}"
  route_table_id = "${aws_route_table.st2_rt.id}"
}


resource "aws_security_group" "vpc_st2" {
    name        = "${var.stack_name}_security_group_${var.name_suffix}"
    description = "Security group for stackstorm VPC"
    vpc_id      = "${aws_vpc.vpc_st2.id}"

    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks     = [ "0.0.0.0/0" ]
    }

    ingress {
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = [ "0.0.0.0/0" ]
        ipv6_cidr_blocks = [ "::/0" ]
    }

    ingress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = [ "0.0.0.0/0" ]
    }

    ingress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        self            = true
    }


    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = [ "0.0.0.0/0" ]
        ipv6_cidr_blocks = [ "::/0" ]
    }

}
