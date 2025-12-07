terraform {
  required_version = ">= 1.0"
  
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key_path = var.private_key_path
  region           = var.region
}

# Get list of availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

# Create Virtual Cloud Network (VCN)
resource "oci_core_vcn" "votex_vcn" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.0.0.0/16"]
  display_name   = "votex-vcn"
  dns_label      = "votexvcn"
}

# Create Internet Gateway
resource "oci_core_internet_gateway" "votex_ig" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.votex_vcn.id
  display_name   = "votex-internet-gateway"
  enabled        = true
}

# Create Route Table
resource "oci_core_route_table" "votex_rt" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.votex_vcn.id
  display_name   = "votex-route-table"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.votex_ig.id
  }
}

# Create Security List (Firewall Rules)
resource "oci_core_security_list" "votex_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.votex_vcn.id
  display_name   = "votex-security-list"

  # Allow incoming SSH (port 22)
  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  # Allow incoming HTTP on port 3000 (React Frontend)
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 3000
      max = 3000
    }
  }

  # Allow incoming HTTP on port 4000 (Node.js Backend)
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false

    tcp_options {
      min = 4000
      max = 4000
    }
  }

  # Allow all outbound traffic
  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless        = false
  }
}

# Create Subnet
resource "oci_core_subnet" "votex_subnet" {
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.votex_vcn.id
  cidr_block        = "10.0.1.0/24"
  display_name      = "votex-subnet"
  dns_label         = "votexsubnet"
  route_table_id    = oci_core_route_table.votex_rt.id
  security_list_ids = [oci_core_security_list.votex_security_list.id]
}

# Get Ubuntu 22.04 image
data "oci_core_images" "ubuntu_images" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "22.04"
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

# Create Compute Instance (Always Free tier)
resource "oci_core_instance" "votex_server" {
  compartment_id      = var.compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "votex-server"
  shape               = var.instance_shape

  # Shape configuration for Always Free tier
  # VM.Standard.E2.1.Micro: 1 OCPU, 1GB RAM
  # VM.Standard.A1.Flex: Up to 4 OCPUs, 24GB RAM (ARM)
  shape_config {
    ocpus         = var.instance_shape == "VM.Standard.A1.Flex" ? 2 : 1
    memory_in_gbs = var.instance_shape == "VM.Standard.A1.Flex" ? 12 : 1
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.votex_subnet.id
    display_name     = "votex-vnic"
    assign_public_ip = true
    hostname_label   = "votex"
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_images.images[0].id
    boot_volume_size_in_gbs = 50
  }

  metadata = {
    ssh_authorized_keys = file(var.ssh_public_key_path)
    user_data           = base64encode(file("${path.module}/cloud-init.yaml"))
  }

  freeform_tags = {
    "Project"     = "VoteX"
    "Environment" = "Production"
    "Tier"        = "AlwaysFree"
  }
}

# Get instance's primary VNIC
data "oci_core_vnic_attachments" "votex_vnic_attachments" {
  compartment_id      = var.compartment_ocid
  instance_id         = oci_core_instance.votex_server.id
}

data "oci_core_vnic" "votex_vnic" {
  vnic_id = data.oci_core_vnic_attachments.votex_vnic_attachments.vnic_attachments[0].vnic_id
}
