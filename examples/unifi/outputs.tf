output "instance_id" {
  description = "OCID of the UniFi instance"
  value       = module.unifi_instance.instance_id
}

output "instance_public_ip" {
  description = "Public IP of the UniFi instance"
  value       = module.unifi_instance.instance_public_ip
}

output "instance_private_ip" {
  description = "Private IP of the UniFi instance"
  value       = module.unifi_instance.instance_private_ip
}

output "reserved_public_ip_id" {
  description = "OCID of the reserved public IP"
  value       = module.unifi_instance.reserved_public_ip_id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = module.unifi_instance.ssh_command
}

output "unifi_web_ui" {
  description = "UniFi Network web interface URLs"
  value = {
    https_8443  = "https://${module.unifi_instance.instance_public_ip}:8443"
    https_11443 = "https://${module.unifi_instance.instance_public_ip}:11443"
  }
}

output "vcn_id" {
  description = "OCID of the VCN"
  value       = module.unifi_instance.vcn_id
}

output "subnet_id" {
  description = "OCID of the subnet"
  value       = module.unifi_instance.subnet_id
}

output "module_info" {
  description = "Module configuration metadata"
  value       = module.unifi_instance.module_info
}
