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
# Public Subnet + NAT Gateway Example
# ============================================================================
# Creates a full-stack infrastructure with a public subnet AND a NAT Gateway.
# The instance has a public IP and inbound internet access via the Internet
# Gateway.  The NAT Gateway is also provisioned in the same VCN so it is
# immediately available for future private subnets or external routing without
# having to redeploy the core network.
#
# Architecture:
#   VCN
#   ├── Internet Gateway  ← route table (0.0.0.0/0) for the public subnet
#   ├── NAT Gateway       ← available via nat_gateway_id output (not wired
#   │                        into this route table — IGW already owns 0.0.0.0/0)
#   └── Public Subnet → Instance (public IP)
# ============================================================================

module "oci_instance" {
  source = "../../"

  # Required
  compartment_id = var.compartment_ocid
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))

  # Instance configuration
  display_name           = var.instance_display_name
  instance_shape         = "VM.Standard.A1.Flex"
  instance_ocpus         = 2
  instance_memory_in_gbs = 12

  # Public subnet with ephemeral public IP (default)
  subnet_type    = "public"
  public_ip_mode = "ephemeral"

  # Explicitly create both gateways in the same VCN:
  # - IGW: wired into the route table (0.0.0.0/0) for this public subnet
  # - NAT GW: provisioned but not wired here — use nat_gateway_id output
  #   to route future private subnets without redeploying the core network
  create_internet_gateway = true
  create_nat_gateway      = true

  # Network addressing
  vcn_cidr_blocks   = ["10.0.0.0/16"]
  subnet_cidr_block = "10.0.1.0/24"
  vcn_dns_label     = "publicnatvnet"
  subnet_dns_label  = "publicnatsubnet"

  # Security: restrict SSH to known CIDRs in production
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  enable_icmp       = true

  freeform_tags = {
    Project     = "Public-NAT-Example"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}
