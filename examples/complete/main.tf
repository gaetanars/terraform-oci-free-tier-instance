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
# Complete Example - All Features
# ============================================================================

module "oci_instance" {
  source = "../../"

  # Required
  compartment_id = var.compartment_ocid
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))

  # Instance Configuration
  display_name            = var.instance_display_name
  instance_shape          = var.instance_shape
  instance_ocpus          = var.instance_ocpus
  instance_memory_in_gbs  = var.instance_memory_in_gbs
  boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  os_version              = var.os_version

  # Network Configuration (Full Stack)
  vcn_cidr_blocks   = [var.vcn_cidr_block]
  subnet_cidr_block = var.subnet_cidr_block
  vcn_dns_label     = "completevnet"
  subnet_dns_label  = "completesubnet"

  # Public IP (Reserved)
  public_ip_mode           = "reserved"
  reserved_ip_display_name = "${var.instance_display_name}-ip"

  # Security - Restrict SSH
  allowed_ssh_cidrs = var.allowed_ssh_cidrs
  enable_icmp       = true

  # Additional custom security rules
  ingress_security_rules = [
    {
      protocol    = "6" # TCP
      source      = "0.0.0.0/0"
      source_type = "CIDR_BLOCK"
      stateless   = false
      description = "HTTP"
      tcp_options = {
        min = 80
        max = 80
      }
      udp_options  = null
      icmp_options = null
    },
    {
      protocol    = "6" # TCP
      source      = "0.0.0.0/0"
      source_type = "CIDR_BLOCK"
      stateless   = false
      description = "HTTPS"
      tcp_options = {
        min = 443
        max = 443
      }
      udp_options  = null
      icmp_options = null
    }
  ]

  # Network Security Group (modern alternative to Security Lists)
  create_nsg       = true
  nsg_display_name = "${var.instance_display_name}-nsg"

  nsg_rules = [
    {
      direction   = "INGRESS"
      protocol    = "6" # TCP
      source      = "0.0.0.0/0"
      source_type = "CIDR_BLOCK"
      stateless   = false
      description = "Allow HTTP via NSG"
      tcp_options = {
        destination_port_range = {
          min = 8080
          max = 8080
        }
      }
    }
  ]

  # Cloud-init (if template file exists)
  cloud_init_template_file = fileexists("${path.module}/cloud-init.yaml") ? "${path.module}/cloud-init.yaml" : null
  cloud_init_template_vars = {
    hostname = var.instance_display_name
    timezone = var.timezone
  }

  # Block Volumes
  block_volumes = [
    {
      display_name     = "${var.instance_display_name}-data"
      size_in_gbs      = 50
      vpus_per_gb      = 10
      backup_policy_id = "bronze"
    }
  ]

  # Boot Volume Backup
  boot_volume_backup_policy = "bronze"

  # Tags
  freeform_tags = {
    Project     = "Complete-Example"
    Environment = "Demo"
    ManagedBy   = "Terraform"
  }
}
