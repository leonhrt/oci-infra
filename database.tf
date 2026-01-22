# Random password for MySQL DB
resource "random_password" "mysql_admin_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]:?"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "oci_vault_secret" "mysql_admin_password" {
  compartment_id = oci_identity_compartment.sandbox.id
  vault_id       = oci_kms_vault.k8s_vault.id
  key_id         = oci_kms_key.master_key.id
  secret_name    = "mysql-admin-password"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(random_password.mysql_admin_password.result)
  }
}

resource "oci_vault_secret" "mysql_admin_username" {
  compartment_id = oci_identity_compartment.sandbox.id
  vault_id       = oci_kms_vault.k8s_vault.id
  key_id         = oci_kms_key.master_key.id
  secret_name    = "mysql-admin-username"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.mysql_admin_username)
  }
}

resource "oci_mysql_mysql_db_system" "mysql_db" {
  compartment_id      = oci_identity_compartment.sandbox.id
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
  subnet_id           = oci_core_subnet.mysql_private_subnet.id

  shape_name              = local.mysql_shape
  data_storage_size_in_gb = local.mysql_storage

  admin_username = var.mysql_admin_username
  admin_password = random_password.mysql_admin_password.result

  display_name        = local.mysql_display_name
  description         = "MySQL Database"
  is_highly_available = false

  nsg_ids = [oci_core_network_security_group.mysql_nsg.id]

  deletion_policy {
    automatic_backup_retention = "DELETE"
    final_backup               = "SKIP_FINAL_BACKUP"
    is_delete_protected        = false
  }
}
