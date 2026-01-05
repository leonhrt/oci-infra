# VCN
resource "oci_core_vcn" "main_vcn" {
  compartment_id = oci_identity_compartment.sandbox.id
  cidr_block     = "10.0.0.0/16"
  display_name   = "sandbox-vcn"
  dns_label      = "sandbox"
}

# Internet Gateway
resource "oci_core_internet_gateway" "main_igw" {
  compartment_id = oci_identity_compartment.sandbox.id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "sandbox-igw"
}

# Route Table
resource "oci_core_route_table" "public_rt" {
  compartment_id = oci_identity_compartment.sandbox.id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "sandbox-public-rt"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main_igw.id
  }
}

# Security List (Firewall)
resource "oci_core_security_list" "public_sl" {
  compartment_id = oci_identity_compartment.sandbox.id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "sandbox-public-sl"

  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  # SSH
  ingress_security_rules {
    protocol = "6" # TCP
    source   = var.allowed_ip
    tcp_options {
      min = 22
      max = 22
    }
  }

  # ICMP (Ping)
  ingress_security_rules {
    protocol = "1"
    source   = var.allowed_ip
  }
}

# Subnet
resource "oci_core_subnet" "public_subnet" {
  compartment_id    = oci_identity_compartment.sandbox.id
  vcn_id            = oci_core_vcn.main_vcn.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "public-subnet"
  route_table_id    = oci_core_route_table.public_rt.id
  security_list_ids = [oci_core_security_list.public_sl.id]
}

# Instance NSG
resource "oci_core_network_security_group" "k3s_master_nsg" {
  compartment_id = oci_identity_compartment.sandbox.id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "k3s-master-security-group"
}

# Network rule of NSG
resource "oci_core_network_security_group_security_rule" "k3s_api_rule" {
  network_security_group_id = oci_core_network_security_group.k3s_master_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP

  source      = var.allowed_ip
  source_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }
}
