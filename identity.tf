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
    "Allow dynamic-group ${oci_identity_dynamic_group.k8s_nodes.name} to read vaults in compartment ${oci_identity_compartment.sandbox.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.k8s_nodes.name} to read secrets in compartment ${oci_identity_compartment.sandbox.name}",
    "Allow dynamic-group ${oci_identity_dynamic_group.k8s_nodes.name} to read secret-bundles in compartment ${oci_identity_compartment.sandbox.name}"
  ]
}

resource "oci_identity_policy" "mysql_service_policy" {
  compartment_id = oci_identity_compartment.sandbox.id
  name           = "mysql-service-policy"
  description    = "Policies for MySQL Database Service"

  statements = [
    "Allow service mysql to use subnets in compartment sandbox",
    "Allow service mysql to use vnics in compartment sandbox",
    "Allow service mysql to use network-security-groups in compartment sandbox",
    "Allow any-user to {NETWORK_SECURITY_GROUP_UPDATE_MEMBERS} in compartment sandbox where all {request.principal.type='mysqldbsystem'}",
    "Allow any-user to {VNIC_CREATE, VNIC_UPDATE, VNIC_ASSOCIATE_NETWORK_SECURITY_GROUP, VNIC_DISASSOCIATE_NETWORK_SECURITY_GROUP} in compartment sandbox where all {request.principal.type='mysqldbsystem'}"
  ]
}
