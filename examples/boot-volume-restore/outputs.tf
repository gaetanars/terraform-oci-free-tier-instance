output "instance_id" {
  description = "OCID of the restored instance"
  value       = module.restored_instance.instance_id
}

output "instance_public_ip" {
  description = "Reserved public IP of the restored instance"
  value       = module.restored_instance.instance_public_ip
}

output "instance_private_ip" {
  description = "Private IP of the restored instance"
  value       = module.restored_instance.instance_private_ip
}

output "boot_volume_id" {
  description = "OCID of the boot volume (same as the input — preserved on termination)"
  value       = module.restored_instance.boot_volume_id
}

output "ssh_command" {
  description = "SSH command to connect to the restored instance"
  value       = module.restored_instance.ssh_command
}
