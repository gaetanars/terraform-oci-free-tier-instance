output "instance_1_public_ip" {
  description = "Public IP of instance-1"
  value       = module.instance_1.instance_public_ip
}

output "instance_2_public_ip" {
  description = "Public IP of instance-2"
  value       = module.instance_2.instance_public_ip
}

output "instance_1_ssh_command" {
  description = "SSH command for instance-1"
  value       = module.instance_1.ssh_command
}

output "instance_2_ssh_command" {
  description = "SSH command for instance-2"
  value       = module.instance_2.ssh_command
}

output "shared_vcn_id" {
  description = "OCID of the shared VCN"
  value       = module.instance_1.vcn_id
}

output "shared_subnet_id" {
  description = "OCID of the shared subnet"
  value       = module.instance_1.subnet_id
}
