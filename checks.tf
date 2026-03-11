# ============================================================================
# Configuration Checks
# These produce warnings during plan/apply but do not block execution.
# They help catch misconfigured or potentially costly settings early.
# ============================================================================

# create_internet_gateway = true is silently ignored in hybrid/existing mode
check "igw_flag_ignored_in_hybrid_mode" {
  assert {
    condition     = !(var.create_internet_gateway && var.vcn_id != null)
    error_message = "create_internet_gateway = true has no effect when vcn_id is provided (hybrid/existing mode). The module cannot create an IGW in an existing VCN. Use internet_gateway_id to reference an existing IGW instead."
  }
}

# create_nat_gateway = true is silently ignored in hybrid/existing mode
check "nat_gw_flag_ignored_in_hybrid_mode" {
  assert {
    condition     = !(var.create_nat_gateway && var.vcn_id != null)
    error_message = "create_nat_gateway = true has no effect when vcn_id is provided (hybrid/existing mode). The module cannot create a NAT Gateway in an existing VCN. Use nat_gateway_id to reference an existing NAT Gateway instead."
  }
}

# create_service_gateway = true is silently ignored in hybrid/existing mode
check "service_gw_flag_ignored_in_hybrid_mode" {
  assert {
    condition     = !(var.create_service_gateway && var.vcn_id != null)
    error_message = "create_service_gateway = true has no effect when vcn_id is provided (hybrid/existing mode). Use service_gateway_id to reference an existing Service Gateway instead."
  }
}

# boot_volume_vpus_per_gb > 20 incurs additional storage costs (Always Free covers 10 and 20 only)
check "boot_volume_vpus_exceeds_free_tier" {
  assert {
    condition     = var.boot_volume_vpus_per_gb <= 20
    error_message = "boot_volume_vpus_per_gb = ${var.boot_volume_vpus_per_gb} exceeds the Always Free limit (max 20). Values above 20 will incur additional storage costs. Use 10 (Balanced) or 20 (Higher Performance) to stay within the free tier."
  }
}

# Public subnet + public IP but no internet route = instance unreachable from internet
check "public_subnet_has_no_internet_route" {
  assert {
    condition = !(
      var.subnet_type == "public" &&
      var.subnet_id == null &&
      var.public_ip_mode != "none" &&
      local.igw_id == null
    )
    error_message = "Public subnet has no Internet Gateway — the instance will receive a public IP but inbound/outbound internet traffic will not be routed. Set create_internet_gateway = true (full-stack mode) or provide internet_gateway_id (hybrid mode) to enable internet connectivity."
  }
}
