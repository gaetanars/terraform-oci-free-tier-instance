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
  default     = "unifi-network-server"
}

variable "ubuntu_version" {
  description = "Ubuntu version to use (e.g., 22.04, 24.04)"
  type        = string
  default     = "24.04"

  validation {
    condition     = can(regex("^\\d+\\.\\d+$", var.ubuntu_version))
    error_message = "Ubuntu version must be in format XX.YY (e.g., 22.04, 24.04)"
  }
}

variable "instance_shape" {
  description = "Shape of the instance (Always Free: VM.Standard.A1.Flex or VM.Standard.E2.1.Micro)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "instance_ocpus" {
  description = "Number of OCPUs (for flexible shapes, max 4 for Always Free)"
  type        = number
  default     = 2
}

variable "instance_memory_in_gbs" {
  description = "Amount of memory in GB (for flexible shapes, max 24 for Always Free)"
  type        = number
  default     = 12
}

variable "boot_volume_size_in_gbs" {
  description = "Size of boot volume in GB (max 200 for Always Free)"
  type        = number
  default     = 50
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
  description = "List of CIDR blocks allowed to SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this to your IP for better security
}

variable "allowed_unifi_cidrs" {
  description = "List of CIDR blocks allowed to access UniFi ports (restrict to your network IPs for better security)"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Restrict this to your network IPs for better security
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Project     = "UniFi-Network"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

variable "timezone" {
  description = "Timezone for the server"
  type        = string
  default     = "Europe/Paris"
}

variable "unifi_os_server_download_url" {
  description = "URL to download UniFi OS Server installer (ARM64 version)"
  type        = string
  default     = "https://fw-download.ubnt.com/data/unifi-os-server/df5b-linux-arm64-5.0.6-f35e944c-f4b6-4190-93a8-be61b96c58f4.6-arm64"
}

variable "auto_updates" {
  description = "Enable automatic security updates"
  type        = bool
  default     = true
}

variable "unattended_upgrades_origins" {
  description = "List of origins allowed for unattended upgrades. Use Ubuntu placeholders like $${distro_id} and $${distro_codename}"
  type        = list(string)
  default = [
    "$${distro_id}:$${distro_codename}",
    "$${distro_id}:$${distro_codename}-security",
    "$${distro_id}ESMApps:$${distro_codename}-apps-security",
    "$${distro_id}ESM:$${distro_codename}-infra-security"
  ]
}

variable "disable_ipv6" {
  description = "Disable IPv6 on the server (optional, for stability)"
  type        = bool
  default     = false
}

# ============================================================================
# UniFi OS Server - Port Configuration
# ============================================================================
# Configure which ports should be accessible from the Internet.
# Each port can be enabled/disabled individually for security.
#
# Recommendation: Enable only the ports you need.
# - After initial setup, disable port 11443 if using Unifi OS Server app
# - UniFi ports should be restricted to your network IPs (use allowed_unifi_cidrs)
# ============================================================================

variable "enable_port_stun" {
  description = "Enable STUN Discovery (3478/udp) - Required for remote access and device discovery"
  type        = bool
  default     = true
}

variable "enable_port_unifi_5005" {
  description = "Enable UniFi Port 5005 (5005/tcp) - Unknown use"
  type        = bool
  default     = false
}

variable "enable_port_remote_logging" {
  description = "Enable Remote Syslog Capture (5514/udp) - Optional, for remote syslog"
  type        = bool
  default     = false
}

variable "enable_port_mobile_speedtest" {
  description = "Enable Mobile Speed Test (6789/tcp) - Required for UniFi mobile app speed test"
  type        = bool
  default     = true
}

variable "enable_port_http" {
  description = "Enable HTTP (80/tcp) - Required for HTTP-01 challenge (Let's Encrypt SSL certificates)"
  type        = bool
  default     = false
}

variable "enable_port_device_adoption" {
  description = "Enable Device Adoption (8080/tcp) - Required for device inform/adoption (restrict IPs via allowed_unifi_cidrs)"
  type        = bool
  default     = true
}

variable "enable_port_https_portal" {
  description = "Enable Application GUI/API (8443/tcp) - Required for web UI on UniFi Console"
  type        = bool
  default     = true
}

variable "enable_port_https_guest_portal" {
  description = "Enable HTTPS Guest Portal (8843/tcp) - Optional, for guest portal HTTPS redirect"
  type        = bool
  default     = true
}

variable "enable_port_secure_portal" {
  description = "Enable Secure Portal for Hotspot (8444/tcp) - Optional, for secure hotspot portal"
  type        = bool
  default     = true
}

variable "enable_port_hotspot_8880" {
  description = "Enable Hotspot Portal Redirection (8880/tcp) - Optional, for guest portal HTTP redirect"
  type        = bool
  default     = true
}

variable "enable_port_hotspot_8881" {
  description = "Enable Hotspot Portal Redirection (8881/tcp) - Optional, for guest portal HTTP redirect"
  type        = bool
  default     = true
}

variable "enable_port_hotspot_8882" {
  description = "Enable Hotspot Portal Redirection (8882/tcp) - Optional, for guest portal HTTP redirect"
  type        = bool
  default     = false
}

variable "enable_port_unifi_9543" {
  description = "Enable UniFi Port 9543 (9543/tcp) - Unknown use"
  type        = bool
  default     = false
}

variable "enable_port_device_discovery" {
  description = "Enable Device Discovery (10001/udp) - Required for device discovery during adoption"
  type        = bool
  default     = true
}

variable "enable_port_unifi_10003" {
  description = "Enable UniFi Port 10003 (10003/udp) - Unknown use"
  type        = bool
  default     = false
}

variable "enable_port_unifi_11084" {
  description = "Enable UniFi Port 11084 (11084/tcp) - Unknown use"
  type        = bool
  default     = false
}

variable "enable_port_websockets" {
  description = "Enable Application GUI/API (11443/tcp) - Required for web browser access and Remote Management"
  type        = bool
  default     = true
}

variable "enable_icmp_ping" {
  description = "Enable ICMP (ping) - Useful for network diagnostics"
  type        = bool
  default     = true
}

# ============================================================================
# ddclient - Dynamic DNS Configuration (Optional)
# ============================================================================
# Configure ddclient to automatically update DNS records when IP changes.
# Useful if you want a domain name that always points to your server.
# Supports multiple providers: Cloudflare, Namecheap, Google Domains, etc.
# ============================================================================

variable "ddclient_enabled" {
  description = "Enable ddclient for dynamic DNS updates"
  type        = bool
  default     = false
}

variable "ddclient_protocol" {
  description = "DNS provider protocol (cloudflare, namecheap, googledomains, etc.)"
  type        = string
  default     = "cloudflare"
}

variable "ddclient_zone" {
  description = "DNS zone/domain (e.g., example.com)"
  type        = string
  default     = ""
}

variable "ddclient_hostname" {
  description = "Hostname to update (e.g., unifi.example.com)"
  type        = string
  default     = ""
}

variable "ddclient_login" {
  description = "DNS provider login/email (leave empty if not required)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ddclient_password" {
  description = "DNS provider API token or password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ddclient_server" {
  description = "DNS provider server (e.g., update.dedyn.io for dyndns2)"
  type        = string
  default     = ""
}

variable "ddclient_use" {
  description = "IP detection method (web, cmd, if, ip)"
  type        = string
  default     = "web"
}

variable "ddclient_cmd" {
  description = "Command for IP detection when use=cmd (e.g., curl https://checkipv4.dedyn.io/)"
  type        = string
  default     = ""
}

variable "ddclient_ssl" {
  description = "Enable SSL for ddclient connections"
  type        = string
  default     = "yes"
}

# ============================================================================
# UniFi Easy Encrypt - SSL Certificate Configuration (Optional)
# ============================================================================
# Automate Let's Encrypt SSL certificate installation for UniFi OS Server
# Using the unifi-easy-encrypt.sh script by Glenn R.
# https://get.glennr.nl/unifi/extra/unifi-easy-encrypt.sh
# ============================================================================

variable "unifi_easy_encrypt_enabled" {
  description = "Enable UniFi Easy Encrypt for automatic Let's Encrypt SSL certificates"
  type        = bool
  default     = false
}

variable "unifi_easy_encrypt_email" {
  description = "Email address for Let's Encrypt notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "unifi_easy_encrypt_fqdn" {
  description = "Fully Qualified Domain Name for the SSL certificate (e.g., unifi.example.com)"
  type        = string
  default     = ""
}

variable "unifi_easy_encrypt_external_dns" {
  description = "External DNS server to resolve the FQDN (e.g., 1.1.1.1, 8.8.8.8)"
  type        = string
  default     = ""
}

variable "unifi_easy_encrypt_run_after_install" {
  description = "Run the script immediately after installation (requires --skip, --email, and --fqdn)"
  type        = bool
  default     = false
}

variable "unifi_easy_encrypt_force_renew" {
  description = "Force certificate renewal even if configuration hasn't changed"
  type        = bool
  default     = false
}
