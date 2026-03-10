output "instance_id" {
  description = "OCID of the instance"
  value       = module.oci_instance.instance_id
}

output "instance_public_ip" {
  description = "Public IP of the instance"
  value       = module.oci_instance.instance_public_ip
}

output "instance_private_ip" {
  description = "Private IP of the instance"
  value       = module.oci_instance.instance_private_ip
}

output "reserved_public_ip_id" {
  description = "OCID of reserved public IP"
  value       = module.oci_instance.reserved_public_ip_id
}

output "vcn_id" {
  description = "OCID of the VCN"
  value       = module.oci_instance.vcn_id
}

output "subnet_id" {
  description = "OCID of the subnet"
  value       = module.oci_instance.subnet_id
}

output "nsg_id" {
  description = "OCID of the Network Security Group"
  value       = module.oci_instance.nsg_id
}

output "block_volume_ids" {
  description = "OCIDs of block volumes"
  value       = module.oci_instance.block_volume_ids
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = module.oci_instance.ssh_command
}

output "module_info" {
  description = "Module configuration metadata"
  value       = module.oci_instance.module_info
}
