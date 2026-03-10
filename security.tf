# ============================================================================
# Security List
# ============================================================================

resource "oci_core_security_list" "this" {
  count = local.create_security_list ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = local.vcn_id
  display_name   = var.security_list_display_name

  # Egress rules
  dynamic "egress_security_rules" {
    for_each = local.all_egress_rules
    content {
      protocol         = egress_security_rules.value.protocol
      destination      = egress_security_rules.value.destination
      destination_type = lookup(egress_security_rules.value, "destination_type", "CIDR_BLOCK")
      stateless        = lookup(egress_security_rules.value, "stateless", false)
      description      = lookup(egress_security_rules.value, "description", null)

      dynamic "tcp_options" {
        for_each = lookup(egress_security_rules.value, "tcp_options", null) != null ? [egress_security_rules.value.tcp_options] : []
        content {
          min = tcp_options.value.min
          max = tcp_options.value.max
        }
      }

      dynamic "udp_options" {
        for_each = lookup(egress_security_rules.value, "udp_options", null) != null ? [egress_security_rules.value.udp_options] : []
        content {
          min = udp_options.value.min
          max = udp_options.value.max
        }
      }

      dynamic "icmp_options" {
        for_each = lookup(egress_security_rules.value, "icmp_options", null) != null ? [egress_security_rules.value.icmp_options] : []
        content {
          type = icmp_options.value.type
          code = lookup(icmp_options.value, "code", null)
        }
      }
    }
  }

  # Ingress rules
  dynamic "ingress_security_rules" {
    for_each = local.all_ingress_rules
    content {
      protocol    = ingress_security_rules.value.protocol
      source      = ingress_security_rules.value.source
      source_type = lookup(ingress_security_rules.value, "source_type", "CIDR_BLOCK")
      stateless   = lookup(ingress_security_rules.value, "stateless", false)
      description = lookup(ingress_security_rules.value, "description", null)

      dynamic "tcp_options" {
        for_each = lookup(ingress_security_rules.value, "tcp_options", null) != null ? [ingress_security_rules.value.tcp_options] : []
        content {
          min = tcp_options.value.min
          max = tcp_options.value.max
        }
      }

      dynamic "udp_options" {
        for_each = lookup(ingress_security_rules.value, "udp_options", null) != null ? [ingress_security_rules.value.udp_options] : []
        content {
          min = udp_options.value.min
          max = udp_options.value.max
        }
      }

      dynamic "icmp_options" {
        for_each = lookup(ingress_security_rules.value, "icmp_options", null) != null ? [ingress_security_rules.value.icmp_options] : []
        content {
          type = icmp_options.value.type
          code = lookup(icmp_options.value, "code", null)
        }
      }
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = length(var.defined_tags) > 0 ? var.defined_tags : null
}

# ============================================================================
# Network Security Group (NSG)
# ============================================================================

resource "oci_core_network_security_group" "this" {
  count = var.create_nsg ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = local.vcn_id
  display_name   = var.nsg_display_name

  freeform_tags = var.freeform_tags
  defined_tags  = length(var.defined_tags) > 0 ? var.defined_tags : null
}

# ============================================================================
# Network Security Group Rules
# ============================================================================

resource "oci_core_network_security_group_security_rule" "nsg_rules" {
  for_each = var.create_nsg ? { for idx, rule in var.nsg_rules : idx => rule } : {}

  network_security_group_id = oci_core_network_security_group.this[0].id
  direction                 = each.value.direction
  protocol                  = each.value.protocol

  # Source (for INGRESS)
  source      = lookup(each.value, "source", null)
  source_type = lookup(each.value, "source_type", "CIDR_BLOCK")

  # Destination (for EGRESS)
  destination      = lookup(each.value, "destination", null)
  destination_type = lookup(each.value, "destination_type", "CIDR_BLOCK")

  stateless   = lookup(each.value, "stateless", false)
  description = lookup(each.value, "description", null)

  # TCP options
  dynamic "tcp_options" {
    for_each = lookup(each.value, "tcp_options", null) != null ? [each.value.tcp_options] : []
    content {
      dynamic "destination_port_range" {
        for_each = lookup(tcp_options.value, "destination_port_range", null) != null ? [tcp_options.value.destination_port_range] : []
        content {
          min = destination_port_range.value.min
          max = destination_port_range.value.max
        }
      }

      dynamic "source_port_range" {
        for_each = lookup(tcp_options.value, "source_port_range", null) != null ? [tcp_options.value.source_port_range] : []
        content {
          min = source_port_range.value.min
          max = source_port_range.value.max
        }
      }
    }
  }

  # UDP options
  dynamic "udp_options" {
    for_each = lookup(each.value, "udp_options", null) != null ? [each.value.udp_options] : []
    content {
      dynamic "destination_port_range" {
        for_each = lookup(udp_options.value, "destination_port_range", null) != null ? [udp_options.value.destination_port_range] : []
        content {
          min = destination_port_range.value.min
          max = destination_port_range.value.max
        }
      }

      dynamic "source_port_range" {
        for_each = lookup(udp_options.value, "source_port_range", null) != null ? [udp_options.value.source_port_range] : []
        content {
          min = source_port_range.value.min
          max = source_port_range.value.max
        }
      }
    }
  }

  # ICMP options
  dynamic "icmp_options" {
    for_each = lookup(each.value, "icmp_options", null) != null ? [each.value.icmp_options] : []
    content {
      type = icmp_options.value.type
      code = lookup(icmp_options.value, "code", null)
    }
  }
}
