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
