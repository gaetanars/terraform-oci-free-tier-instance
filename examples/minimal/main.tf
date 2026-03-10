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
# Minimal Example - Full Stack (VCN + Subnet + Instance)
# ============================================================================

module "oci_instance" {
  source = "../../"

  # Required
  compartment_id = var.compartment_ocid
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))

  # Optional (using defaults)
  display_name = "minimal-instance"

  # Explicitly create IGW for internet access on this public subnet
  create_internet_gateway = true

  # Restrict SSH to your IP — the module no longer opens SSH to 0.0.0.0/0 by default
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}
