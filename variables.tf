# ============================================================================
# Required Variables
# ============================================================================

variable "compartment_id" {
  description = "OCID of the compartment where resources will be created"
  type        = string
}

variable "ssh_public_key" {
  description = "SSH public key content (not path) for instance access"
  type        = string
}

# ============================================================================
# Instance Configuration
# ============================================================================

variable "display_name" {
  description = "Display name for the compute instance"
  type        = string
  default     = "oci-instance"
}

variable "instance_shape" {
  description = "Shape of the instance (Always Free: VM.Standard.A1.Flex or VM.Standard.E2.1.Micro)"
  type        = string
  default     = "VM.Standard.A1.Flex"

  validation {
    condition     = contains(["VM.Standard.A1.Flex", "VM.Standard.E2.1.Micro"], var.instance_shape)
    error_message = "For Always Free tier, use VM.Standard.A1.Flex (ARM) or VM.Standard.E2.1.Micro (x86)"
  }
}

variable "instance_ocpus" {
  description = "Number of OCPUs for flexible shapes (Always Free: max 4 total across all A1.Flex instances)"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_ocpus >= 1 && var.instance_ocpus <= 4
    error_message = "For Always Free tier, OCPUs must be between 1 and 4 (total across all A1.Flex instances)"
  }
}

variable "instance_memory_in_gbs" {
  description = "Amount of memory in GB for flexible shapes (Always Free: max 24GB total across all A1.Flex instances)"
  type        = number
  default     = 12

  validation {
    condition     = var.instance_memory_in_gbs >= 1 && var.instance_memory_in_gbs <= 24
    error_message = "For Always Free tier, memory must be between 1 and 24 GB (total across all A1.Flex instances)"
  }
}

variable "boot_volume_size_in_gbs" {
  description = "Size of boot volume in GB (Always Free: max 200GB total across all instances)"
  type        = number
  default     = 50

  validation {
    condition     = var.boot_volume_size_in_gbs >= 50 && var.boot_volume_size_in_gbs <= 200
    error_message = "Boot volume size must be between 50 and 200 GB for Always Free tier"
  }
}

variable "boot_volume_vpus_per_gb" {
  description = "Volume Performance Units per GB (10 = Balanced, 20 = Higher Performance)"
  type        = number
  default     = 10

  validation {
    condition     = contains([10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 120], var.boot_volume_vpus_per_gb)
    error_message = "Valid values are 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 120"
  }
}

variable "preserve_boot_volume" {
  description = "Whether to preserve boot volume on instance termination"
  type        = bool
  default     = false
}

# ============================================================================
# Image Configuration
# ============================================================================

variable "source_image_id" {
  description = "OCID of the source image. If null, will auto-select Ubuntu based on architecture"
  type        = string
  default     = null
}

variable "os_version" {
  description = "Ubuntu OS version to use when auto-selecting image (e.g., 22.04, 24.04)"
  type        = string
  default     = "24.04"

  validation {
    condition     = can(regex("^\\d+\\.\\d+$", var.os_version))
    error_message = "OS version must be in format XX.YY (e.g., 22.04, 24.04)"
  }
}

# ============================================================================
# Network Configuration - VCN
# ============================================================================

variable "vcn_id" {
  description = "OCID of existing VCN. If null, a new VCN will be created"
  type        = string
  default     = null
}

variable "vcn_cidr_blocks" {
  description = "CIDR blocks for VCN (used when creating new VCN)"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "vcn_display_name" {
  description = "Display name for VCN (used when creating new VCN)"
  type        = string
  default     = "oci-vcn"
}

variable "vcn_dns_label" {
  description = "DNS label for VCN (used when creating new VCN, must be alphanumeric, max 15 chars)"
  type        = string
  default     = "ocivnet"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]{0,14}$", var.vcn_dns_label))
    error_message = "VCN DNS label must start with a letter, be alphanumeric, and max 15 characters"
  }
}

# ============================================================================
# Network Configuration - Subnet
# ============================================================================

variable "subnet_id" {
  description = "OCID of existing subnet. If null and vcn_id is provided, creates subnet in existing VCN. If both are null, creates new VCN and subnet"
  type        = string
  default     = null
}

variable "subnet_cidr_block" {
  description = "CIDR block for subnet (used when creating new subnet)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_display_name" {
  description = "Display name for subnet (used when creating new subnet)"
  type        = string
  default     = "oci-subnet"
}

variable "subnet_dns_label" {
  description = "DNS label for subnet (used when creating new subnet, must be alphanumeric, max 15 chars)"
  type        = string
  default     = "ocisubnet"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]{0,14}$", var.subnet_dns_label))
    error_message = "Subnet DNS label must start with a letter, be alphanumeric, and max 15 characters"
  }
}

variable "subnet_type" {
  description = "Type of subnet: public or private"
  type        = string
  default     = "public"

  validation {
    condition     = contains(["public", "private"], var.subnet_type)
    error_message = "Subnet type must be either 'public' or 'private'"
  }
}

# ============================================================================
# Network Configuration - Internet Gateway & Routing
# ============================================================================

variable "internet_gateway_display_name" {
  description = "Display name for Internet Gateway (used when creating new VCN)"
  type        = string
  default     = "oci-igw"
}

variable "route_table_display_name" {
  description = "Display name for Route Table (used when creating new subnet)"
  type        = string
  default     = "oci-route-table"
}

variable "route_table_id" {
  description = "OCID of existing route table. If null, uses VCN default or creates new one"
  type        = string
  default     = null
}

# ============================================================================
# Public IP Configuration
# ============================================================================

variable "public_ip_mode" {
  description = "Public IP mode: 'reserved' (persistent), 'ephemeral' (temporary), or 'none' (private only)"
  type        = string
  default     = "ephemeral"

  validation {
    condition     = contains(["reserved", "ephemeral", "none"], var.public_ip_mode)
    error_message = "Public IP mode must be 'reserved', 'ephemeral', or 'none'"
  }
}

variable "reserved_ip_display_name" {
  description = "Display name for reserved public IP (used when public_ip_mode = 'reserved')"
  type        = string
  default     = "oci-reserved-ip"
}

# Note: prevent_destroy in lifecycle blocks cannot use variables
# To prevent IP deletion, manually uncomment the lifecycle block in compute.tf

# ============================================================================
# Security Configuration - Security Lists
# ============================================================================

variable "security_list_ids" {
  description = "List of security list OCIDs to attach to subnet. If empty, creates a new security list"
  type        = list(string)
  default     = []
}

variable "security_list_display_name" {
  description = "Display name for security list (used when creating new security list)"
  type        = string
  default     = "oci-security-list"
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to SSH (port 22). Empty list disables SSH ingress rule"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enable_icmp" {
  description = "Enable ICMP (ping) ingress"
  type        = bool
  default     = true
}

variable "ingress_security_rules" {
  description = "Additional custom ingress security rules"
  type = list(object({
    protocol    = string           # "6" (TCP), "17" (UDP), "1" (ICMP), "all"
    source      = string           # CIDR block
    source_type = optional(string) # "CIDR_BLOCK" or "SERVICE_CIDR_BLOCK"
    stateless   = optional(bool)   # Default: false
    description = optional(string) # Rule description
    tcp_options = optional(object({
      min = number # Minimum port
      max = number # Maximum port
    }))
    udp_options = optional(object({
      min = number
      max = number
    }))
    icmp_options = optional(object({
      type = number           # ICMP type
      code = optional(number) # ICMP code
    }))
  }))
  default = []
}

variable "egress_security_rules" {
  description = "Custom egress security rules (default: allow all)"
  type = list(object({
    protocol         = string
    destination      = string
    destination_type = optional(string)
    stateless        = optional(bool)
    description      = optional(string)
    tcp_options = optional(object({
      min = number
      max = number
    }))
    udp_options = optional(object({
      min = number
      max = number
    }))
    icmp_options = optional(object({
      type = number
      code = optional(number)
    }))
  }))
  default = []
}

# ============================================================================
# Security Configuration - Network Security Groups (NSGs)
# ============================================================================

variable "create_nsg" {
  description = "Create a Network Security Group for the instance (modern alternative to Security Lists)"
  type        = bool
  default     = false
}

variable "nsg_display_name" {
  description = "Display name for Network Security Group"
  type        = string
  default     = "oci-nsg"
}

variable "nsg_ids" {
  description = "List of existing NSG OCIDs to attach to the instance VNIC"
  type        = list(string)
  default     = []
}

variable "nsg_rules" {
  description = "Network Security Group rules (used when create_nsg = true)"
  type = list(object({
    direction        = string           # "INGRESS" or "EGRESS"
    protocol         = string           # "6" (TCP), "17" (UDP), "1" (ICMP), "all"
    source           = optional(string) # Required for INGRESS
    destination      = optional(string) # Required for EGRESS
    source_type      = optional(string) # "CIDR_BLOCK", "SERVICE_CIDR_BLOCK", "NETWORK_SECURITY_GROUP"
    destination_type = optional(string)
    stateless        = optional(bool)
    description      = optional(string)
    tcp_options = optional(object({
      destination_port_range = optional(object({
        min = number
        max = number
      }))
      source_port_range = optional(object({
        min = number
        max = number
      }))
    }))
    udp_options = optional(object({
      destination_port_range = optional(object({
        min = number
        max = number
      }))
      source_port_range = optional(object({
        min = number
        max = number
      }))
    }))
    icmp_options = optional(object({
      type = number
      code = optional(number)
    }))
  }))
  default = []
}

# ============================================================================
# Cloud-init / User Data
# ============================================================================

variable "user_data" {
  description = "Base64-encoded user data (cloud-init). Will be base64 encoded automatically if not already"
  type        = string
  default     = null
}

variable "cloud_init_template_file" {
  description = "Path to cloud-init template file (will be rendered with cloud_init_template_vars)"
  type        = string
  default     = null
}

variable "cloud_init_template_vars" {
  description = "Variables to pass to cloud-init template file"
  type        = map(string)
  default     = {}
}

variable "extended_metadata" {
  description = "Additional metadata to pass to the instance"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Storage - Block Volumes
# ============================================================================

variable "block_volumes" {
  description = "Additional block volumes to create and attach to the instance"
  type = list(object({
    display_name     = string
    size_in_gbs      = number
    device_path      = optional(string) # e.g., "/dev/oracleoci/oraclevdb"
    attachment_type  = optional(string) # "paravirtualized" or "iscsi"
    vpus_per_gb      = optional(number) # 10, 20, 30, etc.
    backup_policy_id = optional(string) # OCID of backup policy or "bronze", "silver", "gold"
  }))
  default = []
}

# ============================================================================
# Backup Configuration
# ============================================================================

variable "boot_volume_backup_policy" {
  description = "Backup policy for boot volume: 'bronze', 'silver', 'gold', or custom policy OCID, or null to disable"
  type        = string
  default     = null
}

# ============================================================================
# Multiple VNICs
# ============================================================================

variable "secondary_vnics" {
  description = "Secondary VNICs to attach to the instance"
  type = list(object({
    subnet_id              = string
    display_name           = string
    assign_public_ip       = optional(bool, false)
    hostname_label         = optional(string)
    skip_source_dest_check = optional(bool, false)
  }))
  default = []
}

# ============================================================================
# Availability Domain
# ============================================================================

variable "availability_domain" {
  description = "Availability domain name or index (0, 1, 2). If null, uses first available AD"
  type        = string
  default     = null
}

# ============================================================================
# Tagging
# ============================================================================

variable "freeform_tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "defined_tags" {
  description = "Defined tags to apply to all resources"
  type        = map(string)
  default     = {}
}

# ============================================================================
# Fault Domain
# ============================================================================

variable "fault_domain" {
  description = "Fault domain for the instance (optional)"
  type        = string
  default     = null
}

# ============================================================================
# Instance Options
# ============================================================================

variable "assign_private_dns_record" {
  description = "Whether to assign a private DNS record to the instance"
  type        = bool
  default     = false
}

variable "hostname_label" {
  description = "Hostname label for the primary VNIC (DNS hostname)"
  type        = string
  default     = null
}

variable "skip_source_dest_check" {
  description = "Whether to skip source/destination check on the primary VNIC (required for NAT/routing)"
  type        = bool
  default     = false
}

variable "is_pv_encryption_in_transit_enabled" {
  description = "Enable in-transit encryption for paravirtualized volume attachments. Set to null to leave unmanaged (recommended when importing existing instances)"
  type        = bool
  default     = null
}

# ============================================================================
# Lifecycle Configuration
# ============================================================================

variable "lifecycle_ignore_changes" {
  description = <<-EOT
    List of instance attribute names to ignore changes on. Supported values: "metadata".

    When switching an existing instance to a lifecycle variant (e.g. adding "metadata"),
    add a moved block in your root module to avoid replacement:
      moved {
        from = module.<name>.oci_core_instance.this[0]
        to   = module.<name>.oci_core_instance.this_ignore_metadata[0]
      }
  EOT
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for v in var.lifecycle_ignore_changes : contains(["metadata"], v)])
    error_message = "Supported values for lifecycle_ignore_changes: \"metadata\"."
  }
}
