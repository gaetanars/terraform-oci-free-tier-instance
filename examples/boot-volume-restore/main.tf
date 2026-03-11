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
# Boot Volume Restore Example
#
# Use case: Recreate an instance from an existing boot volume.
# Typical scenarios:
#   - Restore after accidental instance deletion (boot volume preserved)
#   - Migrate an instance to a different AD or shape
#   - Clone an instance from a snapshot
#
# Workflow:
#   Step 1 — Get the boot_volume_id from an existing or previous deployment:
#     terraform output boot_volume_id
#
#   Step 2 — Set boot_volume_id in terraform.tfvars and apply this config.
#
# Notes:
#   - source_type = "bootVolume" always sets preserve_boot_volume = true
#     to protect the source volume from accidental deletion.
#   - Boot volume size and VPU settings are ignored when source_type = "bootVolume"
#     (the volume retains its original size and performance tier).
#   - The module skips Ubuntu image auto-selection when source_type = "bootVolume".
# ============================================================================

module "restored_instance" {
  source = "../../"

  compartment_id = var.compartment_ocid
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))

  display_name = "restored-instance"

  # Boot from an existing boot volume instead of a fresh image
  source_type    = "bootVolume"
  boot_volume_id = var.boot_volume_id

  # Network — reuse existing infrastructure
  vcn_id    = var.vcn_id
  subnet_id = var.subnet_id

  # Keep the public IP stable across restores
  public_ip_mode              = "reserved"
  reserved_ip_prevent_destroy = true

  allowed_ssh_cidrs = var.allowed_ssh_cidrs
}
