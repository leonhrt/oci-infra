resource "oci_identity_dynamic_group" "k8s_nodes" {
  compartment_id = var.tenancy_ocid
  name           = "k8s-nodes"
  description    = "K8s cluster nodes for vault access"
  matching_rule  = "instance.compartment.id = '${oci_identity_compartment.sandbox.id}'"
}

resource "oci_identity_policy" "k8s_vault_access" {
  compartment_id = oci_identity_compartment.sandbox.id
  name           = "k8s-vault-access"
  description    = "Allow k8s nodes to read secrets from vault"

  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.k8s_nodes.name} to read secret-bundles in compartment ${oci_identity_compartment.sandbox.name}"
  ]
}
