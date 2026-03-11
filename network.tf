# ============================================================================
# Virtual Cloud Network (VCN)
# ============================================================================

resource "oci_core_vcn" "this" {
  count = local.create_vcn ? 1 : 0

  compartment_id = var.compartment_id
  display_name   = var.vcn_display_name
  dns_label      = var.vcn_dns_label
  cidr_blocks    = var.vcn_cidr_blocks

  freeform_tags = var.freeform_tags
  defined_tags  = length(var.defined_tags) > 0 ? var.defined_tags : null
}

# ============================================================================
# Internet Gateway
# ============================================================================

resource "oci_core_internet_gateway" "this" {
  count = local.create_igw ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = local.vcn_id
  display_name   = var.internet_gateway_display_name
  enabled        = true

  freeform_tags = var.freeform_tags
  defined_tags  = length(var.defined_tags) > 0 ? var.defined_tags : null
}

# ============================================================================
# NAT Gateway
# ============================================================================

resource "oci_core_nat_gateway" "this" {
  count = local.create_nat_gw ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = local.vcn_id
  display_name   = var.nat_gateway_display_name
  block_traffic  = false

  freeform_tags = var.freeform_tags
  defined_tags  = length(var.defined_tags) > 0 ? var.defined_tags : null
}

# ============================================================================
# Service Gateway
# ============================================================================

# OCI "All Services" CIDR — used as the Service Gateway destination in the route table
data "oci_core_services" "all_oci_services" {
  count = local.create_service_gw || var.service_gateway_id != null ? 1 : 0

  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "this" {
  count = local.create_service_gw ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = local.vcn_id
  display_name   = var.service_gateway_display_name

  services {
    service_id = data.oci_core_services.all_oci_services[0].services[0].id
  }

  freeform_tags = var.freeform_tags
  defined_tags  = length(var.defined_tags) > 0 ? var.defined_tags : null
}

# ============================================================================
# Route Table
# ============================================================================

resource "oci_core_route_table" "this" {
  count = local.create_subnet ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = local.vcn_id
  display_name   = var.route_table_display_name

  # Add route to Internet Gateway for public subnets with an IGW:
  # - full-stack mode: uses the IGW created by this module
  # - hybrid mode: uses var.internet_gateway_id (must be provided by the caller)
  dynamic "route_rules" {
    for_each = local.igw_id != null && var.subnet_type == "public" ? [1] : []
    content {
      network_entity_id = local.igw_id
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      description       = "Route to Internet Gateway"
    }
  }

  # Add route to NAT Gateway for:
  # - private subnets (always, when a NAT GW is available)
  # - public subnets without an IGW (outbound-only internet via NAT GW)
  dynamic "route_rules" {
    for_each = local.nat_gw_id != null && (var.subnet_type == "private" || local.igw_id == null) ? [1] : []
    content {
      network_entity_id = local.nat_gw_id
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      description       = "Route to NAT Gateway"
    }
  }

  # Add route to Service Gateway for OCI internal services (Object Storage, etc.)
  dynamic "route_rules" {
    for_each = local.service_gw_id != null ? [1] : []
    content {
      network_entity_id = local.service_gw_id
      destination       = data.oci_core_services.all_oci_services[0].services[0].cidr_block
      destination_type  = "SERVICE_CIDR_BLOCK"
      description       = "Route to OCI Service Gateway (Object Storage and other OCI services)"
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = length(var.defined_tags) > 0 ? var.defined_tags : null
}

# ============================================================================
# Subnet
# ============================================================================

resource "oci_core_subnet" "this" {
  count = local.create_subnet ? 1 : 0

  compartment_id             = var.compartment_id
  vcn_id                     = local.vcn_id
  display_name               = var.subnet_display_name
  dns_label                  = var.subnet_dns_label
  cidr_block                 = var.subnet_cidr_block
  prohibit_public_ip_on_vnic = var.subnet_type == "private"
  prohibit_internet_ingress  = var.subnet_type == "private"

  # Use created route table or provided route_table_id
  route_table_id = local.route_table_id

  # Security lists: use created or provided
  security_list_ids = local.security_list_ids

  freeform_tags = var.freeform_tags
  defined_tags  = length(var.defined_tags) > 0 ? var.defined_tags : null
}
