# ============================================================================
# Compute Instance
# ============================================================================

resource "oci_core_instance" "this" {
  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = var.display_name
  shape               = var.instance_shape
  fault_domain        = var.fault_domain

  # Shape configuration (only for flexible shapes)
  dynamic "shape_config" {
    for_each = local.is_flex_shape ? [1] : []
    content {
      ocpus         = var.instance_ocpus
      memory_in_gbs = var.instance_memory_in_gbs
    }
  }

  # Source details (boot volume)
  source_details {
    source_type             = var.source_type
    source_id               = var.source_type == "bootVolume" ? var.boot_volume_id : local.selected_image_id
    boot_volume_size_in_gbs = var.source_type == "image" ? var.boot_volume_size_in_gbs : null
    boot_volume_vpus_per_gb = var.source_type == "image" ? var.boot_volume_vpus_per_gb : null
  }

  # Primary VNIC configuration
  create_vnic_details {
    subnet_id                 = local.subnet_id
    display_name              = "${var.display_name}-vnic"
    assign_public_ip          = local.assign_ephemeral_ip
    assign_private_dns_record = var.assign_private_dns_record
    hostname_label            = var.hostname_label
    skip_source_dest_check    = var.skip_source_dest_check
    nsg_ids                   = local.nsg_ids
  }

  # Metadata (SSH keys + user_data)
  metadata = local.instance_metadata

  # Preserve boot volume on instance termination
  # When source_type = "bootVolume", the boot volume is the source and must be preserved
  preserve_boot_volume = var.source_type == "bootVolume" ? true : var.preserve_boot_volume

  # Enable in-transit encryption for paravirtualized attachments
  is_pv_encryption_in_transit_enabled = var.is_pv_encryption_in_transit_enabled

  # Ignore changes to source_id to prevent replacement when image updates in "image" mode
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }

  freeform_tags = var.freeform_tags
  defined_tags  = length(var.defined_tags) > 0 ? var.defined_tags : null
}

# Migration: move existing state from this_ignore_metadata[0] to this
# TODO: remove this block in v2.0.0 once all users have migrated
moved {
  from = oci_core_instance.this_ignore_metadata[0]
  to   = oci_core_instance.this
}

# ============================================================================
# Reserved Public IP - Create and Assign to Primary VNIC Private IP
# ============================================================================

resource "oci_core_public_ip" "this" {
  count = local.create_reserved_ip ? 1 : 0

  compartment_id = var.compartment_id
  lifetime       = "RESERVED"
  display_name   = var.reserved_ip_display_name
  private_ip_id  = data.oci_core_private_ips.primary_vnic_private_ips.private_ips[0].id

  # Note: prevent_destroy cannot use variables in Terraform
  # Uncomment and set to true manually in production if needed
  # lifecycle {
  #   prevent_destroy = true
  # }

  freeform_tags = var.freeform_tags
  defined_tags  = length(var.defined_tags) > 0 ? var.defined_tags : null

  depends_on = [
    oci_core_instance.this,
    data.oci_core_private_ips.primary_vnic_private_ips
  ]
}

# ============================================================================
# Secondary VNICs
# ============================================================================

resource "oci_core_vnic_attachment" "secondary_vnics" {
  # Keyed by display_name — must be unique across all secondary VNICs
  for_each = { for vnic in var.secondary_vnics : vnic.display_name => vnic }

  instance_id  = oci_core_instance.this.id
  display_name = each.value.display_name

  create_vnic_details {
    subnet_id              = each.value.subnet_id
    display_name           = each.value.display_name
    assign_public_ip       = each.value.assign_public_ip
    hostname_label         = each.value.hostname_label
    skip_source_dest_check = each.value.skip_source_dest_check
  }

  depends_on = [
    oci_core_instance.this,
  ]
}
