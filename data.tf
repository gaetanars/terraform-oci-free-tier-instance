# ============================================================================
# Availability Domains
# ============================================================================

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.compartment_id
}

# ============================================================================
# Ubuntu Images - ARM64 Architecture (for VM.Standard.A1.Flex)
# ============================================================================

data "oci_core_images" "ubuntu_arm" {
  # Only fetched when auto-selecting an image for an ARM shape
  count = var.source_image_id == null && var.source_type == "image" && can(regex("A1", var.instance_shape)) ? 1 : 0

  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = var.os_version
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"

  filter {
    name   = "display_name"
    values = [".*aarch64.*"]
    regex  = true
  }
}

# ============================================================================
# Ubuntu Images - x86_64 Architecture (for VM.Standard.E2.1.Micro)
# ============================================================================

data "oci_core_images" "ubuntu_amd" {
  # Only fetched when auto-selecting an image for an x86 shape
  count = var.source_image_id == null && var.source_type == "image" && !can(regex("A1", var.instance_shape)) ? 1 : 0

  compartment_id           = var.compartment_id
  operating_system         = "Canonical Ubuntu"
  operating_system_version = var.os_version
  shape                    = "VM.Standard.E2.1.Micro"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"

  filter {
    name   = "display_name"
    values = [".*amd64.*"]
    regex  = true
  }
}

# ============================================================================
# VNIC Attachments (fetched after instance creation)
# ============================================================================

data "oci_core_vnic_attachments" "instance_vnics" {
  compartment_id      = var.compartment_id
  instance_id         = oci_core_instance.this.id
  availability_domain = local.availability_domain

  depends_on = [
    oci_core_instance.this,
  ]
}

# ============================================================================
# Primary VNIC Details
# ============================================================================

data "oci_core_vnic" "primary_vnic" {
  vnic_id = data.oci_core_vnic_attachments.instance_vnics.vnic_attachments[0].vnic_id

  depends_on = [
    oci_core_instance.this,
  ]
}

# ============================================================================
# Private IPs on Primary VNIC
# ============================================================================

data "oci_core_private_ips" "primary_vnic_private_ips" {
  vnic_id = data.oci_core_vnic.primary_vnic.id

  depends_on = [
    oci_core_instance.this,
  ]
}
