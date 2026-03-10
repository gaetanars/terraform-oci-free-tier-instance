output "instance_id" {
  description = "OCID of the instance"
  value       = module.oci_instance.instance_id
}

output "instance_private_ip" {
  description = "Private IP of the instance"
  value       = module.oci_instance.instance_private_ip
}

output "nat_gateway_id" {
  description = "OCID of the NAT Gateway"
  value       = module.oci_instance.nat_gateway_id
}

output "module_info" {
  description = "Module configuration metadata"
  value       = module.oci_instance.module_info
}
