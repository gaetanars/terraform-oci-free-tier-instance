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
# Private Subnet + NAT Gateway Example
# ============================================================================
# Creates a full-stack infrastructure with a private subnet and a NAT Gateway,
# allowing the instance to initiate outbound internet connections (e.g., package
# updates, API calls) while remaining unreachable from the internet.
#
# Architecture:
#   VCN → NAT Gateway → Route Table → Private Subnet → Instance (no public IP)
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

  # Private subnet — no public IP on the instance
  subnet_type    = "private"
  public_ip_mode = "none"

  # NAT Gateway: allows outbound internet access from the private subnet
  create_nat_gateway = true

  # Network addressing
  vcn_cidr_blocks   = ["10.0.0.0/16"]
  subnet_cidr_block = "10.0.1.0/24"
  vcn_dns_label     = "privatenatvnet"
  subnet_dns_label  = "privatenatsubnet"

  # Security: no SSH from internet (instance is private)
  # Access via Bastion, VPN, or OCI Cloud Shell instead
  allowed_ssh_cidrs = []
  enable_icmp       = false

  freeform_tags = {
    Project     = "Private-NAT-Example"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}
