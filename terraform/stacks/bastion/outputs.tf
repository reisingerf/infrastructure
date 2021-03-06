# output for user: florian
output "florian_username" {
  value = "${module.florian_user.username}"
}

output "florian_access_key" {
  value = "${module.florian_user.access_key}"
}

output "florian_secret_access_key" {
  value = "${module.florian_user.encrypted_secret_access_key}"
}

output "florian_console_login" {
  value = "${aws_iam_user_login_profile.florian_console_login.encrypted_password}"
}

# output for user: brainstorm
output "brainstorm_username" {
  value = "${module.brainstorm_user.username}"
}

output "brainstorm_access_key" {
  value = "${module.brainstorm_user.access_key}"
}

output "brainstorm_secret_access_key" {
  value = "${module.brainstorm_user.encrypted_secret_access_key}"
}

output "brainstorm_console_login" {
  value = "${aws_iam_user_login_profile.brainstorm_console_login.encrypted_password}"
}

# output for user: oliver
output "oliver_username" {
  value = "${module.oliver_user.username}"
}

output "oliver_access_key" {
  value = "${module.oliver_user.access_key}"
}

output "oliver_secret_access_key" {
  value = "${module.oliver_user.encrypted_secret_access_key}"
}

output "oliver_console_login" {
  value = "${aws_iam_user_login_profile.oliver_console_login.encrypted_password}"
}

# output for user: vlad
output "vlad_username" {
  value = "${module.vlad_user.username}"
}

output "vlad_access_key" {
  value = "${module.vlad_user.access_key}"
}

output "vlad_secret_access_key" {
  value = "${module.vlad_user.encrypted_secret_access_key}"
}

output "vlad_console_login" {
  value = "${aws_iam_user_login_profile.vlad_console_login.encrypted_password}"
}

# output for user: lavinia
output "lavinia_username" {
  value = "${module.lavinia_user.username}"
}

output "lavinia_access_key" {
  value = "${module.lavinia_user.access_key}"
}

output "lavinia_secret_access_key" {
  value = "${module.lavinia_user.encrypted_secret_access_key}"
}

output "lavinia_console_login" {
  value = "${aws_iam_user_login_profile.lavinia_console_login.encrypted_password}"
}

# output for user: pdiakumis
output "pdiakumis_username" {
  value = "${module.pdiakumis_user.username}"
}

output "pdiakumis_access_key" {
  value = "${module.pdiakumis_user.access_key}"
}

output "pdiakumis_secret_access_key" {
  value = "${module.pdiakumis_user.encrypted_secret_access_key}"
}

output "pdiakumis_console_login" {
  value = "${aws_iam_user_login_profile.pdiakumis_console_login.encrypted_password}"
}

# output for serivce: packer
output "packer_username" {
  value = "${module.packer_user.username}"
}

output "packer_access_key" {
  value = "${module.packer_user.access_key}"
}

output "packer_secret_access_key" {
  value = "${module.packer_user.encrypted_secret_access_key}"
}

# output for serivce: terraform
output "terraform_username" {
  value = "${module.terraform_user.username}"
}

output "terraform_access_key" {
  value = "${module.terraform_user.access_key}"
}

output "terraform_secret_access_key" {
  value = "${module.terraform_user.encrypted_secret_access_key}"
}

# output for serivce: sample_monitor
output "sample_monitor_username" {
  value = "${module.sample_monitor_user.username}"
}

output "sample_monitor_access_key" {
  value = "${module.sample_monitor_user.access_key}"
}

output "sample_monitor_secret_access_key" {
  value = "${module.sample_monitor_user.encrypted_secret_access_key}"
}
