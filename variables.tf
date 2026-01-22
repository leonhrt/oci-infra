variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "region" {}
variable "ssh_public_key" {}

variable "allowed_ip" {
  description = "Allowed IP for administration"
  type        = string
}

variable "mysql_admin_username" {
  description = "MySQL admin username"
  type        = string
}
