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
  defined_tags  = var.defined_tags
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
  defined_tags  = var.defined_tags
}

# ============================================================================
# Route Table
# ============================================================================

resource "oci_core_route_table" "this" {
  count = local.create_subnet ? 1 : 0

  compartment_id = var.compartment_id
  vcn_id         = local.vcn_id
  display_name   = var.route_table_display_name

  # Add route to Internet Gateway if created (for public subnets)
  dynamic "route_rules" {
    for_each = local.create_igw ? [1] : []
    content {
      network_entity_id = oci_core_internet_gateway.this[0].id
      destination       = "0.0.0.0/0"
      destination_type  = "CIDR_BLOCK"
      description       = "Route to Internet Gateway"
    }
  }

  freeform_tags = var.freeform_tags
  defined_tags  = var.defined_tags
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
  defined_tags  = var.defined_tags
}
