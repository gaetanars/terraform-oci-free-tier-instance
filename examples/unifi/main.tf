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
# UniFi Network Server Example
# ============================================================================
# This example shows how to deploy UniFi OS Server using the module.
# It demonstrates the migration from the original terraform/ code.
# ============================================================================

# Build UniFi-specific security rules from enable_port_* variables
locals {
  unifi_security_rules = concat(
    # HTTP (80/tcp) - For Let's Encrypt
    var.enable_port_http ? [{
      protocol     = "6"
      source       = "0.0.0.0/0"
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "HTTP for Let's Encrypt HTTP-01 challenge"
      tcp_options  = { min = 80, max = 80 }
      udp_options  = null
      icmp_options = null
    }] : [],

    # STUN Discovery (3478/udp)
    var.enable_port_stun ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "17"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi STUN Discovery"
      tcp_options  = null
      udp_options  = { min = 3478, max = 3478 }
      icmp_options = null
    }] : [],

    # UniFi Port 5005 (5005/tcp)
    var.enable_port_unifi_5005 ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "6"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi Port 5005"
      tcp_options  = { min = 5005, max = 5005 }
      udp_options  = null
      icmp_options = null
    }] : [],

    # Remote Syslog (5514/udp)
    var.enable_port_remote_logging ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "17"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi Remote Syslog"
      tcp_options  = null
      udp_options  = { min = 5514, max = 5514 }
      icmp_options = null
    }] : [],

    # Mobile Speed Test (6789/tcp)
    var.enable_port_mobile_speedtest ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "6"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi Mobile Speed Test"
      tcp_options  = { min = 6789, max = 6789 }
      udp_options  = null
      icmp_options = null
    }] : [],

    # Device Adoption (8080/tcp)
    var.enable_port_device_adoption ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "6"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi Device Adoption"
      tcp_options  = { min = 8080, max = 8080 }
      udp_options  = null
      icmp_options = null
    }] : [],

    # Application GUI/API (8443/tcp)
    var.enable_port_https_portal ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "6"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi Application GUI/API"
      tcp_options  = { min = 8443, max = 8443 }
      udp_options  = null
      icmp_options = null
    }] : [],

    # HTTPS Guest Portal (8843/tcp)
    var.enable_port_https_guest_portal ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "6"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi HTTPS Guest Portal"
      tcp_options  = { min = 8843, max = 8843 }
      udp_options  = null
      icmp_options = null
    }] : [],

    # Secure Portal for Hotspot (8444/tcp)
    var.enable_port_secure_portal ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "6"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi Secure Hotspot Portal"
      tcp_options  = { min = 8444, max = 8444 }
      udp_options  = null
      icmp_options = null
    }] : [],

    # Hotspot Portal Redirection (8880/tcp)
    var.enable_port_hotspot_8880 ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "6"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi Hotspot Portal 8880"
      tcp_options  = { min = 8880, max = 8880 }
      udp_options  = null
      icmp_options = null
    }] : [],

    # Hotspot Portal Redirection (8881/tcp)
    var.enable_port_hotspot_8881 ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "6"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi Hotspot Portal 8881"
      tcp_options  = { min = 8881, max = 8881 }
      udp_options  = null
      icmp_options = null
    }] : [],

    # Hotspot Portal Redirection (8882/tcp)
    var.enable_port_hotspot_8882 ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "6"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi Hotspot Portal 8882"
      tcp_options  = { min = 8882, max = 8882 }
      udp_options  = null
      icmp_options = null
    }] : [],

    # UniFi Port 9543 (9543/tcp)
    var.enable_port_unifi_9543 ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "6"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi Port 9543"
      tcp_options  = { min = 9543, max = 9543 }
      udp_options  = null
      icmp_options = null
    }] : [],

    # Device Discovery (10001/udp)
    var.enable_port_device_discovery ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "17"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi Device Discovery"
      tcp_options  = null
      udp_options  = { min = 10001, max = 10001 }
      icmp_options = null
    }] : [],

    # UniFi Port 10003 (10003/udp)
    var.enable_port_unifi_10003 ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "17"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi Port 10003"
      tcp_options  = null
      udp_options  = { min = 10003, max = 10003 }
      icmp_options = null
    }] : [],

    # UniFi Port 11084 (11084/tcp)
    var.enable_port_unifi_11084 ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "6"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi Port 11084"
      tcp_options  = { min = 11084, max = 11084 }
      udp_options  = null
      icmp_options = null
    }] : [],

    # WebSockets (11443/tcp)
    var.enable_port_websockets ? [for cidr in var.allowed_unifi_cidrs : {
      protocol     = "6"
      source       = cidr
      source_type  = "CIDR_BLOCK"
      stateless    = false
      description  = "UniFi WebSockets/Remote Management"
      tcp_options  = { min = 11443, max = 11443 }
      udp_options  = null
      icmp_options = null
    }] : []
  )
}

module "unifi_instance" {
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
  os_version              = var.ubuntu_version

  # Network (Full Stack)
  vcn_cidr_blocks   = [var.vcn_cidr_block]
  subnet_cidr_block = var.subnet_cidr_block
  vcn_dns_label     = "unifinet"
  subnet_dns_label  = "unifisubnet"

  # Public IP (Reserved)
  public_ip_mode           = "reserved"
  reserved_ip_display_name = "unifi-reserved-ip"

  # Security
  allowed_ssh_cidrs      = var.allowed_ssh_cidrs
  enable_icmp            = var.enable_icmp_ping
  ingress_security_rules = local.unifi_security_rules

  # Cloud-init
  cloud_init_template_file = "${path.module}/cloud-init.yaml"
  cloud_init_template_vars = {
    hostname = var.instance_display_name
    timezone = var.timezone
  }

  # Tags
  freeform_tags = var.tags
}
