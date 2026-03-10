variable "tenancy_ocid" {
  description = "OCID of your tenancy"
  type        = string
  sensitive   = true
}

variable "user_ocid" {
  description = "OCID of the user"
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "Fingerprint of the API key"
  type        = string
  sensitive   = true
}

variable "private_key_path" {
  description = "Path to your private API key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Oracle Cloud region"
  type        = string
  default     = "eu-paris-1"
}

variable "compartment_ocid" {
  description = "OCID of the compartment"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "instance_display_name" {
  description = "Display name for the instance"
  type        = string
  default     = "complete-instance"
}

variable "instance_shape" {
  description = "Shape of the instance"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs"
  type        = number
  default     = 2
}

variable "instance_memory_in_gbs" {
  description = "Memory in GB"
  type        = number
  default     = 12
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size in GB"
  type        = number
  default     = 100
}

variable "os_version" {
  description = "Ubuntu OS version"
  type        = string
  default     = "24.04"
}

variable "vcn_cidr_block" {
  description = "CIDR block for VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr_block" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "allowed_ssh_cidrs" {
  description = "Allowed CIDR blocks for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "timezone" {
  description = "Timezone for the server"
  type        = string
  default     = "Europe/Paris"
}
