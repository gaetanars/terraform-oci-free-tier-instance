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

output "nat_gateway_id" {
  description = "OCID of the NAT Gateway (use in route tables for future private subnets)"
  value       = module.oci_instance.nat_gateway_id
}

output "internet_gateway_id" {
  description = "OCID of the Internet Gateway"
  value       = module.oci_instance.internet_gateway_id
}

output "vcn_id" {
  description = "OCID of the VCN"
  value       = module.oci_instance.vcn_id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = module.oci_instance.ssh_command
}

output "module_info" {
  description = "Module configuration metadata"
  value       = module.oci_instance.module_info
}
