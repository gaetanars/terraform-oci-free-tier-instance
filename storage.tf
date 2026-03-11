# ============================================================================
# Block Volumes
# ============================================================================

resource "oci_core_volume" "block_volumes" {
  # Keyed by display_name — must be unique across all block volumes
  for_each = { for vol in var.block_volumes : vol.display_name => vol }

  compartment_id      = var.compartment_id
  availability_domain = local.availability_domain
  display_name        = each.value.display_name
  size_in_gbs         = each.value.size_in_gbs
  vpus_per_gb         = lookup(each.value, "vpus_per_gb", 10)

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
}

# ============================================================================
# Block Volume Attachments
# ============================================================================

resource "oci_core_volume_attachment" "block_volume_attachments" {
  for_each = { for vol in var.block_volumes : vol.display_name => vol }

  attachment_type = lookup(each.value, "attachment_type", "paravirtualized")
  instance_id     = oci_core_instance.this.id
  volume_id       = oci_core_volume.block_volumes[each.key].id

  # Device path (optional)
  device = lookup(each.value, "device_path", null)

  # Enable in-transit encryption for paravirtualized attachments
  is_pv_encryption_in_transit_enabled = (
    lookup(each.value, "attachment_type", "paravirtualized") == "paravirtualized" ?
    var.is_pv_encryption_in_transit_enabled :
    null
  )

  depends_on = [
    oci_core_instance.this,
    oci_core_volume.block_volumes
  ]
}

# ============================================================================
# Block Volume Backup Policy Assignments
# ============================================================================

# Data source for predefined backup policies
data "oci_core_volume_backup_policies" "predefined_policies" {
  count = length(var.block_volumes) > 0 ? 1 : 0

  filter {
    name   = "display_name"
    values = ["bronze", "silver", "gold"]
  }
}

# Assign backup policies to block volumes
resource "oci_core_volume_backup_policy_assignment" "block_volume_backup_assignments" {
  for_each = {
    for vol in var.block_volumes :
    vol.display_name => vol
    if lookup(vol, "backup_policy_id", null) != null
  }

  asset_id = oci_core_volume.block_volumes[each.key].id
  policy_id = (
    # If backup_policy_id is "bronze", "silver", or "gold", find the OCID from predefined policies
    # one() returns null on empty list (clearer error than index out of bounds)
    contains(["bronze", "silver", "gold"], each.value.backup_policy_id) ?
    one([for policy in data.oci_core_volume_backup_policies.predefined_policies[0].volume_backup_policies :
      policy.id if lower(policy.display_name) == lower(each.value.backup_policy_id)
    ]) :
    # Otherwise, assume it's a custom policy OCID
    each.value.backup_policy_id
  )

  depends_on = [
    oci_core_volume.block_volumes
  ]
}
