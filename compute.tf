# Available availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Available Ubuntu Server 24.04 ARM images
data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = local.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Main instance config
resource "oci_core_instance" "k3s_server" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
  compartment_id      = oci_identity_compartment.sandbox.id
  display_name        = "k3s-server"
  shape               = local.instance_shape

  shape_config {
    ocpus         = local.instance_ocpus
    memory_in_gbs = local.instance_memory
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = 80
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.public_subnet.id
    assign_public_ip = true
    nsg_ids          = [oci_core_network_security_group.k3s_master_nsg.id]
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key)
  }
}

data "oci_core_images" "ubuntu_amd_minimal" {
  compartment_id           = var.tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04 Minimal"
  shape                    = local.ts_server_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "ts_server" {
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[1].name
  compartment_id      = oci_identity_compartment.sandbox.id
  display_name        = "ts-server"
  shape               = local.ts_server_shape

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_amd_minimal.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.ts_subnet.id
    assign_public_ip = true
  }

  metadata = {
    ssh_authorized_keys = file(var.ts_ssh_public_key)
  }
}
