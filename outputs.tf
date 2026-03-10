# ============================================================================
# Instance Outputs
# ============================================================================

output "instance_id" {
  description = "OCID of the compute instance"
  value       = oci_core_instance.this.id
}

output "instance_state" {
  description = "State of the compute instance"
  value       = oci_core_instance.this.state
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = data.oci_core_vnic.primary_vnic.private_ip_address
}

output "instance_public_ip" {
  description = "Public IP address of the instance (null if public_ip_mode = 'none')"
  value = (
    local.create_reserved_ip ? oci_core_public_ip.this[0].ip_address :
    local.assign_ephemeral_ip ? data.oci_core_vnic.primary_vnic.public_ip_address :
    null
  )
}

output "instance_display_name" {
  description = "Display name of the instance"
  value       = oci_core_instance.this.display_name
}

output "instance_region" {
  description = "Region where the instance is located"
  value       = oci_core_instance.this.region
}

output "instance_availability_domain" {
  description = "Availability domain where the instance is located"
  value       = oci_core_instance.this.availability_domain
}

output "instance_fault_domain" {
  description = "Fault domain where the instance is located"
  value       = oci_core_instance.this.fault_domain
}

output "instance_shape" {
  description = "Shape of the instance"
  value       = oci_core_instance.this.shape
}

output "instance_shape_config" {
  description = "Shape configuration (OCPUs and memory for flexible shapes)"
  value       = local.is_flex_shape ? oci_core_instance.this.shape_config : null
}

# ============================================================================
# Network Outputs
# ============================================================================

output "vcn_id" {
  description = "OCID of the VCN (created or existing)"
  value       = local.vcn_id
}

output "subnet_id" {
  description = "OCID of the subnet (created or existing)"
  value       = local.subnet_id
}

output "internet_gateway_id" {
  description = "OCID of the Internet Gateway (if created)"
  value       = local.create_igw ? oci_core_internet_gateway.this[0].id : null
}

output "nat_gateway_id" {
  description = "OCID of the NAT Gateway (if created)"
  value       = local.create_nat_gw ? oci_core_nat_gateway.this[0].id : null
}

output "route_table_id" {
  description = "OCID of the route table (created or existing)"
  value       = local.route_table_id
}

output "primary_vnic_id" {
  description = "OCID of the primary VNIC"
  value       = data.oci_core_vnic.primary_vnic.id
}

output "primary_vnic_private_ip_id" {
  description = "OCID of the primary VNIC's private IP"
  value       = data.oci_core_private_ips.primary_vnic_private_ips.private_ips[0].id
}

# ============================================================================
# Security Outputs
# ============================================================================

output "security_list_id" {
  description = "OCID of the security list (if created)"
  value       = local.create_security_list ? oci_core_security_list.this[0].id : null
}

output "nsg_id" {
  description = "OCID of the Network Security Group (if created)"
  value       = var.create_nsg ? oci_core_network_security_group.this[0].id : null
}

# ============================================================================
# Public IP Outputs
# ============================================================================

output "reserved_public_ip_id" {
  description = "OCID of the reserved public IP (if created)"
  value       = local.create_reserved_ip ? oci_core_public_ip.this[0].id : null
}

output "reserved_public_ip_address" {
  description = "IP address of the reserved public IP (if created)"
  value       = local.create_reserved_ip ? oci_core_public_ip.this[0].ip_address : null
}

# ============================================================================
# Block Volumes Outputs
# ============================================================================

output "block_volume_ids" {
  description = "OCIDs of additional block volumes (if created)"
  value       = { for k, v in oci_core_volume.block_volumes : k => v.id }
}

output "block_volume_attachments" {
  description = "Details of block volume attachments"
  value = {
    for k, v in oci_core_volume_attachment.block_volume_attachments : k => {
      id          = v.id
      state       = v.state
      device      = v.device
      volume_id   = v.volume_id
      instance_id = v.instance_id
    }
  }
}

# ============================================================================
# Secondary VNICs Outputs
# ============================================================================

output "secondary_vnic_ids" {
  description = "OCIDs of secondary VNICs (if created)"
  value       = { for k, v in oci_core_vnic_attachment.secondary_vnics : k => v.vnic_id }
}

output "secondary_vnic_private_ips" {
  description = "Private IPs of secondary VNICs (if created)"
  value       = { for k, v in oci_core_vnic_attachment.secondary_vnics : k => v.private_ip_address }
}

# ============================================================================
# Boot Volume Outputs
# ============================================================================

output "boot_volume_id" {
  description = "OCID of the boot volume"
  value       = oci_core_instance.this.boot_volume_id
}

# ============================================================================
# Helper Outputs
# ============================================================================

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value = (
    local.has_public_ip ?
    "ssh ${var.ssh_user}@${local.create_reserved_ip ? oci_core_public_ip.this[0].ip_address : data.oci_core_vnic.primary_vnic.public_ip_address}" :
    "Instance has no public IP (private only)"
  )
}

# ============================================================================
# Module Metadata
# ============================================================================

output "module_info" {
  description = "Metadata about the module configuration"
  value       = local.module_info
}
