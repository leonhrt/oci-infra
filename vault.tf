resource "oci_kms_vault" "k8s_vault" {
  compartment_id = oci_identity_compartment.sandbox.id
  display_name   = "k8s-vault"
  vault_type     = "DEFAULT"
}

resource "oci_kms_key" "master_key" {
  compartment_id = oci_identity_compartment.sandbox.id
  display_name   = "master-key"

  key_shape {
    algorithm = "AES"
    length    = 32
  }

  management_endpoint = oci_kms_vault.k8s_vault.management_endpoint
  protection_mode     = "SOFTWARE"
}
