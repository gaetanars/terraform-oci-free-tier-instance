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

output "ssh_command" {
  description = "SSH command to connect"
  value       = module.oci_instance.ssh_command
}

output "module_info" {
  description = "Module configuration metadata"
  value       = module.oci_instance.module_info
}

output "vcn_id" {
  description = "OCID of the existing VCN used"
  value       = oci_core_vcn.existing.id
}

output "subnet_id" {
  description = "OCID of the existing subnet used"
  value       = oci_core_subnet.existing.id
}
