terraform {
  required_version = ">= 1.9.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.0"
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

# ============================================================================
# Existing Network Example
# ============================================================================
# This example shows how to use the module with an existing VCN and subnet.
# Uncomment the module call below after creating the VCN and subnet resources
# or use your existing VCN/subnet OCIDs.
# ============================================================================

# Example: Create VCN and subnet separately (or use existing ones)
resource "oci_core_vcn" "existing" {
  compartment_id = var.compartment_ocid
  display_name   = "existing-vcn"
  dns_label      = "existingvnet"
  cidr_blocks    = ["10.1.0.0/16"]
}

resource "oci_core_internet_gateway" "existing" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.existing.id
  display_name   = "existing-igw"
  enabled        = true
}

resource "oci_core_route_table" "existing" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.existing.id
  display_name   = "existing-route-table"

  route_rules {
    network_entity_id = oci_core_internet_gateway.existing.id
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "existing" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.existing.id
  display_name   = "existing-security-list"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 22
      max = 22
    }
  }
}

resource "oci_core_subnet" "existing" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.existing.id
  display_name               = "existing-subnet"
  dns_label                  = "existingsubnet"
  cidr_block                 = "10.1.1.0/24"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.existing.id
  security_list_ids          = [oci_core_security_list.existing.id]
}

# Module using existing VCN and subnet
module "oci_instance" {
  source = "../../"

  # Required
  compartment_id = var.compartment_ocid
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))

  # Use existing VCN and subnet
  vcn_id    = oci_core_vcn.existing.id
  subnet_id = oci_core_subnet.existing.id

  # Optionally use existing security list
  security_list_ids = [oci_core_security_list.existing.id]

  # Instance configuration
  display_name            = var.instance_display_name
  instance_shape          = "VM.Standard.A1.Flex"
  instance_ocpus          = 2
  instance_memory_in_gbs  = 12
  boot_volume_size_in_gbs = 50

  # Public IP (Reserved)
  public_ip_mode           = "reserved"
  reserved_ip_display_name = "${var.instance_display_name}-ip"

  # The module won't create VCN, subnet, IGW, or route table
  # It will only create the instance and attach it to the existing subnet

  freeform_tags = {
    Project     = "Existing-Network-Example"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}
