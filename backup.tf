# ============================================================================
# Boot Volume Backup Policy Assignment
# ============================================================================

# Data source for predefined backup policies
data "oci_core_volume_backup_policies" "boot_volume_policies" {
  count = var.boot_volume_backup_policy != null ? 1 : 0

  filter {
    name   = "display_name"
    values = ["bronze", "silver", "gold"]
  }
}

# Assign backup policy to boot volume
resource "oci_core_volume_backup_policy_assignment" "boot_volume_backup" {
  count = var.boot_volume_backup_policy != null ? 1 : 0

  asset_id = oci_core_instance.this.boot_volume_id
  policy_id = (
    # If backup_policy is "bronze", "silver", or "gold", find the OCID from predefined policies
    contains(["bronze", "silver", "gold"], var.boot_volume_backup_policy) ?
    [for policy in data.oci_core_volume_backup_policies.boot_volume_policies[0].volume_backup_policies :
      policy.id if lower(policy.display_name) == lower(var.boot_volume_backup_policy)
    ][0] :
    # Otherwise, assume it's a custom policy OCID
    var.boot_volume_backup_policy
  )

  depends_on = [
    oci_core_instance.this,
  ]
}
