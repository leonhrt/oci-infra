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

# Services from Oracle
data "oci_core_services" "all_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# Service Gateway
resource "oci_core_service_gateway" "service_gw" {
  compartment_id = oci_identity_compartment.sandbox.id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "sandbox-service-gateway"

  services {
    service_id = data.oci_core_services.all_services.services[0].id
  }
}

# Private Route Table
resource "oci_core_route_table" "mysql_private_rt" {
  compartment_id = oci_identity_compartment.sandbox.id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "mysql-sandbox-private-rt"

  route_rules {
    destination       = data.oci_core_services.all_services.services[0].cidr_block
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = oci_core_service_gateway.service_gw.id
  }
}

# Security List Private Subnet for DB
resource "oci_core_security_list" "mysql_private_sl" {
  compartment_id = oci_identity_compartment.sandbox.id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "mysql-private-subnet-sl"

  egress_security_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }
}

# Private subnet for DB
resource "oci_core_subnet" "mysql_private_subnet" {
  compartment_id             = oci_identity_compartment.sandbox.id
  vcn_id                     = oci_core_vcn.main_vcn.id
  cidr_block                 = "10.0.3.0/24"
  display_name               = "mysql-private-subnet"
  dns_label                  = "dbpriv"
  route_table_id             = oci_core_route_table.mysql_private_rt.id
  security_list_ids          = [oci_core_security_list.mysql_private_sl.id]
  prohibit_public_ip_on_vnic = true
}

# NSG DB
resource "oci_core_network_security_group" "mysql_nsg" {
  compartment_id = oci_identity_compartment.sandbox.id
  vcn_id         = oci_core_vcn.main_vcn.id
  display_name   = "mysql-nsg"
}

# NSG Ingress Rule DB
resource "oci_core_network_security_group_security_rule" "mysql_nsg_ingress_rule" {
  network_security_group_id = oci_core_network_security_group.mysql_nsg.id
  direction                 = "INGRESS"
  protocol                  = "6" # TCP
  description               = "MySQL port from K3s instances only"

  source      = oci_core_network_security_group.k3s_master_nsg.id
  source_type = "NETWORK_SECURITY_GROUP"

  tcp_options {
    destination_port_range {
      min = 3306
      max = 3306
    }
  }
}

# NSG Oracle Services Egress Rule DB 
resource "oci_core_network_security_group_security_rule" "mysql_nsg_egress_services_rule" {
  network_security_group_id = oci_core_network_security_group.mysql_nsg.id
  direction                 = "EGRESS"
  protocol                  = "6" # TCP
  description               = "Allow access to Oracle Services"

  destination      = data.oci_core_services.all_services.services[0].cidr_block
  destination_type = "SERVICE_CIDR_BLOCK"
}
