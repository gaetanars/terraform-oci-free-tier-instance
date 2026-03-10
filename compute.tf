# ============================================================================
# Compute Instance
# ============================================================================

# Default lifecycle: metadata changes are applied
resource "oci_core_instance" "this" {
  count = local._lifecycle_ignore_metadata ? 0 : 1

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
    source_type             = "image"
    source_id               = local.selected_image_id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    boot_volume_vpus_per_gb = var.boot_volume_vpus_per_gb
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
  preserve_boot_volume = var.preserve_boot_volume

  # Enable in-transit encryption for paravirtualized attachments
  is_pv_encryption_in_transit_enabled = var.is_pv_encryption_in_transit_enabled

  # Ignore changes to source_id to prevent replacement when image updates
  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# Lifecycle variant: metadata changes are ignored
# Activate with: lifecycle_ignore_changes = ["metadata"]
# When migrating an existing instance from the default variant, add in your root module:
#   moved {
#     from = module.<name>.oci_core_instance.this[0]
#     to   = module.<name>.oci_core_instance.this_ignore_metadata[0]
#   }
resource "oci_core_instance" "this_ignore_metadata" {
  count = local._lifecycle_ignore_metadata ? 1 : 0

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
    source_type             = "image"
    source_id               = local.selected_image_id
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
    boot_volume_vpus_per_gb = var.boot_volume_vpus_per_gb
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
  preserve_boot_volume = var.preserve_boot_volume

  # Enable in-transit encryption for paravirtualized attachments
  is_pv_encryption_in_transit_enabled = var.is_pv_encryption_in_transit_enabled

  lifecycle {
    ignore_changes = [source_details[0].source_id, metadata]
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
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
  defined_tags  = var.defined_tags

  depends_on = [
    oci_core_instance.this,
    oci_core_instance.this_ignore_metadata,
    data.oci_core_private_ips.primary_vnic_private_ips
  ]
}

# ============================================================================
# Secondary VNICs
# ============================================================================

resource "oci_core_vnic_attachment" "secondary_vnics" {
  for_each = { for idx, vnic in var.secondary_vnics : idx => vnic }

  instance_id  = local.instance.id
  display_name = each.value.display_name

  create_vnic_details {
    subnet_id              = each.value.subnet_id
    display_name           = each.value.display_name
    assign_public_ip       = lookup(each.value, "assign_public_ip", false)
    hostname_label         = lookup(each.value, "hostname_label", null)
    skip_source_dest_check = lookup(each.value, "skip_source_dest_check", false)
  }

  depends_on = [
    oci_core_instance.this,
    oci_core_instance.this_ignore_metadata,
  ]
}
