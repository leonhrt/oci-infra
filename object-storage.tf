data "oci_objectstorage_namespace" "ns" {
  compartment_id = oci_identity_compartment.sandbox.id
}

resource "oci_objectstorage_bucket" "cs2_bucket" {
  compartment_id = oci_identity_compartment.sandbox.id
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = "cs2-bucket"
  access_type    = "ObjectRead"
}
