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
# Multi-Instance Example — Shared VCN (Hybrid Mode)
#
# Use case: Maximize the Always Free A1.Flex quota (4 OCPUs / 24 GB RAM total)
# by splitting it across multiple instances sharing a single VCN.
#
# Network topology:
#   VCN (10.0.0.0/16)
#   └── public subnet (10.0.1.0/24)  ← IGW
#       ├── instance-1  (2 OCPU / 12 GB)
#       └── instance-2  (2 OCPU / 12 GB)
#
# Pattern: the first module call creates the full-stack (VCN + subnet + IGW).
# Subsequent calls reuse the VCN and subnet via hybrid mode (vcn_id + subnet_id).
# ============================================================================

# First instance — creates the shared VCN, subnet, and IGW
module "instance_1" {
  source = "../../"

  compartment_id = var.compartment_ocid
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))

  display_name = "instance-1"

  # Full-stack: let this module create the VCN, subnet, and IGW
  create_internet_gateway = true
  vcn_display_name        = "shared-vcn"
  subnet_display_name     = "shared-public-subnet"

  instance_ocpus         = 2
  instance_memory_in_gbs = 12

  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}

# Second instance — reuses the VCN and subnet created by instance_1
module "instance_2" {
  source = "../../"

  compartment_id = var.compartment_ocid
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))

  display_name = "instance-2"

  # Hybrid mode: reuse the existing VCN and subnet
  vcn_id    = module.instance_1.vcn_id
  subnet_id = module.instance_1.subnet_id

  instance_ocpus         = 2
  instance_memory_in_gbs = 12

  allowed_ssh_cidrs = var.allowed_ssh_cidrs

  depends_on = [module.instance_1]
}
