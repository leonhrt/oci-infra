resource "oci_identity_compartment" "sandbox" {
  compartment_id = var.tenancy_ocid
  name           = local.compartment_name
  description    = "Compartment as used as a sandbox"
  enable_delete  = true
}
