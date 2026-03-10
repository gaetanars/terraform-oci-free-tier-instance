# Oracle Cloud Free Tier Instance Module

A universal, reusable Terraform module for deploying compute instances on Oracle Cloud Infrastructure (OCI) Always Free tier.

## Features

- **Always Free Compatible**: Validates resources stay within OCI Always Free limits
- **Flexible Network Modes**: Full stack (VCN + subnet + instance), hybrid, or existing network
- **Public IP Options**: Reserved (persistent), ephemeral (temporary), or none (private)
- **NAT Gateway Support**: Private subnets with outbound internet access (no inbound exposure)
- **Auto Image Selection**: Automatically selects Ubuntu ARM or x86 images based on shape
- **Security Options**: Security Lists and/or Network Security Groups (NSGs)
- **Block Volumes**: Additional storage with automated attachment
- **Backup Policies**: Automated backups for boot and block volumes
- **Cloud-init Support**: Template-based server initialization
- **Multiple VNICs**: Secondary network interfaces

## Always Free Tier Limits

This module validates configurations stay within OCI Always Free limits:

- **Compute**: Up to 4 OCPUs and 24 GB RAM total across all VM.Standard.A1.Flex instances
- **Storage**: Up to 200 GB total across all boot and block volumes
- **Shapes**: VM.Standard.A1.Flex (ARM) or VM.Standard.E2.1.Micro (x86)
- **Public IPs**: 2 reserved public IPs included

## Network Modes

The module automatically detects the network mode based on provided variables:

### 1. Full Stack Mode (Default)

Creates complete infrastructure: VCN → Subnet → IGW → Route Table → Instance

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  compartment_id = var.compartment_id
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  # vcn_id and subnet_id are null (default)
  # Module creates everything
}
```

### 2. Existing Network Mode

Uses existing VCN and subnet, only creates instance:

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  compartment_id = var.compartment_id
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  vcn_id    = "ocid1.vcn.oc1...."
  subnet_id = "ocid1.subnet.oc1...."
}
```

### 3. Hybrid Mode

Uses existing VCN, creates new subnet. For public subnets, provide the existing IGW OCID via `internet_gateway_id` so the module can add the default route:

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  compartment_id = var.compartment_id
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  vcn_id               = "ocid1.vcn.oc1...."
  subnet_cidr_block    = "10.0.2.0/24"
  internet_gateway_id  = "ocid1.internetgateway.oc1...."  # required for public subnet
}
```

### 4. Private Subnet with NAT Gateway (Full Stack)

Creates a private subnet with a NAT Gateway for outbound-only internet access. The instance has no public IP and is unreachable from the internet:

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  compartment_id = var.compartment_id
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  subnet_type        = "private"
  public_ip_mode     = "none"
  create_nat_gateway = true  # NAT GW created in full-stack mode
}
```

In hybrid mode (existing VCN), provide the existing NAT Gateway OCID instead:

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  compartment_id = var.compartment_id
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  vcn_id         = "ocid1.vcn.oc1...."
  subnet_type    = "private"
  public_ip_mode = "none"
  nat_gateway_id = "ocid1.natgateway.oc1...."  # required for outbound access
}
```

## Public IP Modes

### Reserved IP (Recommended for Production)

Persistent IP that survives instance restarts and recreations:

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  # ... required vars ...

  public_ip_mode           = "reserved"
  reserved_ip_display_name = "my-reserved-ip"
  # To prevent accidental deletion, uncomment the lifecycle block in compute.tf
}
```

### Ephemeral IP (Default)

Temporary IP that changes when instance restarts:

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  # ... required vars ...

  public_ip_mode = "ephemeral"  # or omit (default)
}
```

### No Public IP (Private)

Instance accessible only via private network:

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  # ... required vars ...

  public_ip_mode = "none"
}
```

## Basic Usage

### Minimal Configuration

```hcl
module "oci_instance" {
  source = "./modules/oci-free-tier-instance"

  # Required
  compartment_id = "ocid1.compartment.oc1...."
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  # SSH is closed by default — explicitly allow your IP
  allowed_ssh_cidrs = ["1.2.3.4/32"]
}
```

This creates:
- VCN with CIDR 10.0.0.0/16
- Public subnet 10.0.1.0/24
- VM.Standard.A1.Flex instance (2 OCPUs, 12GB RAM)
- Ephemeral public IP
- Security list with SSH (restricted) + ICMP rules

### Complete Configuration

```hcl
module "oci_instance" {
  source = "./modules/oci-free-tier-instance"

  # Required
  compartment_id = var.compartment_id
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))

  # Instance
  display_name            = "my-instance"
  instance_shape          = "VM.Standard.A1.Flex"
  instance_ocpus          = 4
  instance_memory_in_gbs  = 24
  boot_volume_size_in_gbs = 100
  os_version              = "24.04"

  # Network
  vcn_cidr_blocks   = ["10.1.0.0/16"]
  subnet_cidr_block = "10.1.1.0/24"
  vcn_dns_label     = "myvnet"
  subnet_dns_label  = "mysubnet"

  # Public IP
  public_ip_mode           = "reserved"
  reserved_ip_display_name = "my-ip"

  # Security
  allowed_ssh_cidrs = ["1.2.3.4/32"]
  enable_icmp       = true

  ingress_security_rules = [
    {
      protocol    = "6"
      source      = "0.0.0.0/0"
      tcp_options = { min = 80, max = 80 }
      description = "HTTP"
    },
    {
      protocol    = "6"
      source      = "0.0.0.0/0"
      tcp_options = { min = 443, max = 443 }
      description = "HTTPS"
    }
  ]

  # Cloud-init
  cloud_init_template_file = "${path.module}/cloud-init.yaml"
  cloud_init_template_vars = {
    hostname = "my-instance"
  }

  # Block volumes
  block_volumes = [
    {
      display_name     = "data-volume"
      size_in_gbs      = 50
      backup_policy_id = "bronze"
    }
  ]

  # Backup
  boot_volume_backup_policy = "bronze"

  # Tags
  freeform_tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Security Configuration

### Security Lists (Traditional)

Default rules are created automatically (SSH + ICMP). Add custom rules:

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  # ... required vars ...

  allowed_ssh_cidrs = ["1.2.3.4/32"]  # Restrict SSH
  enable_icmp       = true             # Enable ping

  ingress_security_rules = [
    {
      protocol    = "6"           # TCP
      source      = "0.0.0.0/0"
      tcp_options = { min = 80, max = 80 }
      description = "HTTP"
    },
    {
      protocol    = "17"          # UDP
      source      = "10.0.0.0/8"
      udp_options = { min = 3478, max = 3478 }
      description = "STUN"
    }
  ]
}
```

### Network Security Groups (Modern)

NSGs are the modern alternative to Security Lists:

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  # ... required vars ...

  create_nsg = true

  nsg_rules = [
    {
      direction   = "INGRESS"
      protocol    = "6"
      source      = "0.0.0.0/0"
      description = "HTTP"
      tcp_options = {
        destination_port_range = { min = 80, max = 80 }
      }
    },
    {
      direction   = "EGRESS"
      protocol    = "all"
      destination = "0.0.0.0/0"
      description = "Allow all outbound"
    }
  ]
}
```

## Block Volumes

Add persistent storage:

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  # ... required vars ...

  block_volumes = [
    {
      display_name     = "data"
      size_in_gbs      = 50
      vpus_per_gb      = 10
      backup_policy_id = "bronze"  # or "silver", "gold", or OCID
    },
    {
      display_name = "logs"
      size_in_gbs  = 50
    }
  ]
}
```

After deployment, format and mount:

```bash
ssh ubuntu@<instance-ip>
lsblk
sudo mkfs.ext4 /dev/sdb
sudo mkdir -p /mnt/data
sudo mount /dev/sdb /mnt/data
echo '/dev/sdb /mnt/data ext4 defaults 0 2' | sudo tee -a /etc/fstab
```

## Cloud-init

### Inline User Data

Pass plain text — the module base64-encodes it automatically:

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  # ... required vars ...

  user_data = <<-EOF
    #cloud-config
    packages:
      - nginx
    runcmd:
      - systemctl enable nginx
      - systemctl start nginx
  EOF
}
```

### Template File

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  # ... required vars ...

  cloud_init_template_file = "${path.module}/cloud-init.yaml"
  cloud_init_template_vars = {
    hostname = "webserver"
    timezone = "Europe/Paris"
  }
}
```

`cloud-init.yaml`:
```yaml
#cloud-config
hostname: ${hostname}
timezone: ${timezone}

packages:
  - nginx
  - certbot
```

## Multiple VNICs

Attach secondary network interfaces:

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  # ... required vars ...

  secondary_vnics = [
    {
      subnet_id        = "ocid1.subnet.oc1...."
      display_name     = "secondary-vnic"
      assign_public_ip = false
    }
  ]
}
```

## Inputs

### Required

| Name | Description | Type |
|------|-------------|------|
| `compartment_id` | OCID of the compartment where resources will be created | `string` |
| `ssh_public_key` | SSH public key content (not path) for instance access | `string` |

### Instance

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `display_name` | Display name for the compute instance | `string` | `"oci-instance"` |
| `instance_shape` | Shape of the instance (`VM.Standard.A1.Flex` or `VM.Standard.E2.1.Micro`) | `string` | `"VM.Standard.A1.Flex"` |
| `instance_ocpus` | Number of OCPUs (1–4 for Always Free) | `number` | `2` |
| `instance_memory_in_gbs` | Memory in GB (1–24 for Always Free) | `number` | `12` |
| `boot_volume_size_in_gbs` | Boot volume size in GB (50–200) | `number` | `50` |
| `boot_volume_vpus_per_gb` | Boot volume VPUs/GB — **values > 20 are not Always Free** | `number` | `10` |
| `preserve_boot_volume` | Preserve boot volume on instance termination | `bool` | `true` |
| `source_type` | Boot source: `image` for fresh install, `bootVolume` to reuse an existing boot volume | `string` | `"image"` |
| `boot_volume_id` | OCID of the boot volume to use when `source_type = "bootVolume"` | `string` | `null` |
| `availability_domain` | Availability domain name or index (0, 1, 2). If null, uses first available AD | `string` | `null` |
| `fault_domain` | Fault domain for the instance | `string` | `null` |
| `is_pv_encryption_in_transit_enabled` | Enable in-transit encryption for paravirtualized attachments | `bool` | `null` |

### Image

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `os_version` | Ubuntu version for auto-selection (e.g. `22.04`, `24.04`) | `string` | `"24.04"` |
| `source_image_id` | Custom image OCID. If null, auto-selects Ubuntu based on architecture | `string` | `null` |

### Network — VCN

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `vcn_id` | Existing VCN OCID. If null, creates a new VCN | `string` | `null` |
| `vcn_cidr_blocks` | CIDR blocks for the VCN (used when creating new VCN) | `list(string)` | `["10.0.0.0/16"]` |
| `vcn_display_name` | Display name for the VCN | `string` | `"oci-vcn"` |
| `vcn_dns_label` | DNS label for the VCN (alphanumeric, max 15 chars) | `string` | `"ocivnet"` |

### Network — Subnet

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `subnet_id` | Existing subnet OCID. If null, creates a new subnet | `string` | `null` |
| `subnet_cidr_block` | CIDR block for the subnet | `string` | `"10.0.1.0/24"` |
| `subnet_display_name` | Display name for the subnet | `string` | `"oci-subnet"` |
| `subnet_dns_label` | DNS label for the subnet (alphanumeric, max 15 chars) | `string` | `"ocisubnet"` |
| `subnet_type` | Type of subnet: `public` or `private` | `string` | `"public"` |

### Network — Routing & Gateway

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `internet_gateway_id` | Existing IGW OCID — required for hybrid mode with public subnet | `string` | `null` |
| `internet_gateway_display_name` | Display name for the Internet Gateway | `string` | `"oci-igw"` |
| `create_nat_gateway` | Create a NAT Gateway for outbound internet from private subnet (full-stack mode only) | `bool` | `false` |
| `nat_gateway_id` | Existing NAT Gateway OCID — used in hybrid mode with private subnet | `string` | `null` |
| `nat_gateway_display_name` | Display name for the NAT Gateway | `string` | `"oci-nat-gateway"` |
| `route_table_id` | Existing route table OCID. If null, uses VCN default or creates new | `string` | `null` |
| `route_table_display_name` | Display name for the route table | `string` | `"oci-route-table"` |

### Public IP

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `public_ip_mode` | Public IP mode: `reserved`, `ephemeral`, or `none` | `string` | `"ephemeral"` |
| `reserved_ip_display_name` | Display name for the reserved public IP | `string` | `"oci-reserved-ip"` |

### Security — Security Lists

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `security_list_ids` | Existing security list OCIDs to attach. If empty, creates a new one | `list(string)` | `[]` |
| `security_list_display_name` | Display name for the security list | `string` | `"oci-security-list"` |
| `allowed_ssh_cidrs` | Allowed SSH CIDRs — **empty by default, SSH is closed unless set** | `list(string)` | `[]` |
| `enable_icmp` | Enable ICMP (ping) ingress | `bool` | `true` |
| `ingress_security_rules` | Additional custom ingress security rules | `list(object)` | `[]` |
| `egress_security_rules` | Custom egress rules (default: allow all) | `list(object)` | `[]` |

### Security — Network Security Groups (NSGs)

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `create_nsg` | Create a Network Security Group for the instance | `bool` | `false` |
| `nsg_display_name` | Display name for the NSG | `string` | `"oci-nsg"` |
| `nsg_ids` | Existing NSG OCIDs to attach to the instance VNIC | `list(string)` | `[]` |
| `nsg_rules` | NSG rules (used when `create_nsg = true`) | `list(object)` | `[]` |

### Cloud-init

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `user_data` | Plain text cloud-init (base64-encoded automatically) | `string` | `null` |
| `cloud_init_template_file` | Path to cloud-init template file | `string` | `null` |
| `cloud_init_template_vars` | Variables to pass to the cloud-init template | `map(string)` | `{}` |
| `extended_metadata` | Additional metadata to pass to the instance | `map(string)` | `{}` |

### Storage

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `block_volumes` | Block volumes to create and attach (`display_name` must be unique) | `list(object)` | `[]` |
| `boot_volume_backup_policy` | Backup policy for boot volume: `bronze`, `silver`, `gold`, or OCID | `string` | `null` |

### Secondary VNICs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `secondary_vnics` | Secondary VNICs to attach to the instance | `list(object)` | `[]` |

### Instance Options

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `ssh_user` | Username for the `ssh_command` output | `string` | `"ubuntu"` |
| `hostname_label` | Hostname label for the primary VNIC (DNS hostname) | `string` | `null` |
| `assign_private_dns_record` | Assign a private DNS record to the instance | `bool` | `false` |
| `skip_source_dest_check` | Skip source/destination check (required for NAT/routing) | `bool` | `false` |

### Tagging

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `freeform_tags` | Freeform tags applied to all resources | `map(string)` | `{}` |
| `defined_tags` | Defined tags applied to all resources | `map(string)` | `{}` |

See [variables.tf](./variables.tf) for full type definitions and validations.

## Outputs

### Instance

| Name | Description |
|------|-------------|
| `instance_id` | OCID of the compute instance |
| `instance_state` | State of the compute instance |
| `instance_display_name` | Display name of the instance |
| `instance_region` | Region where the instance is located |
| `instance_availability_domain` | Availability domain of the instance |
| `instance_fault_domain` | Fault domain of the instance |
| `instance_shape` | Shape of the instance |
| `instance_shape_config` | Shape configuration (OCPUs and memory for flexible shapes) |
| `instance_public_ip` | Public IP address (null if `public_ip_mode = "none"`) |
| `instance_private_ip` | Private IP address |
| `boot_volume_id` | OCID of the boot volume |

### Network

| Name | Description |
|------|-------------|
| `vcn_id` | OCID of the VCN (created or existing) |
| `subnet_id` | OCID of the subnet (created or existing) |
| `internet_gateway_id` | OCID of the Internet Gateway (if created) |
| `nat_gateway_id` | OCID of the NAT Gateway (if created) |
| `route_table_id` | OCID of the route table (created or existing) |
| `primary_vnic_id` | OCID of the primary VNIC |
| `primary_vnic_private_ip_id` | OCID of the primary VNIC's private IP |

### Security

| Name | Description |
|------|-------------|
| `security_list_id` | OCID of the security list (if created) |
| `nsg_id` | OCID of the Network Security Group (if created) |

### Public IP

| Name | Description |
|------|-------------|
| `reserved_public_ip_id` | OCID of the reserved public IP (if created) |
| `reserved_public_ip_address` | IP address of the reserved public IP (if created) |

### Block Volumes

| Name | Description |
|------|-------------|
| `block_volume_ids` | Map of block volume names to OCIDs |
| `block_volume_attachments` | Map of block volume attachment details |

### Secondary VNICs

| Name | Description |
|------|-------------|
| `secondary_vnic_ids` | Map of secondary VNIC names to OCIDs |
| `secondary_vnic_private_ips` | Map of secondary VNIC names to private IPs |

### Helpers

| Name | Description |
|------|-------------|
| `ssh_command` | Ready-to-use SSH command to connect to the instance |
| `module_info` | Module metadata and configuration summary |

See [outputs.tf](./outputs.tf) for full output definitions.

## Examples

See the [examples/](./examples/) directory:

- **[minimal/](./examples/minimal/)**: Minimal configuration (3 lines)
- **[complete/](./examples/complete/)**: All features demonstrated
- **[existing-network/](./examples/existing-network/)**: Using existing VCN/subnet
- **[private-nat/](./examples/private-nat/)**: Private subnet with NAT Gateway (outbound-only internet)
- **[unifi/](./examples/unifi/)**: UniFi Network Server deployment

## Requirements

- Terraform >= 1.9.0
- OCI Provider ~> 7.0
- Valid OCI credentials and compartment

## License

This module is part of the [UniFi Oracle Cloud](https://github.com/gaetanars/unifi-oracle-cloud) project.

## Author

GaëtanArs

## Contributing

Contributions welcome! This module is designed to be universal and reusable.

## Troubleshooting

### Instance not accessible

Check security list rules and public IP assignment:

```bash
terraform output module_info
```

### Always Free limit exceeded

Validate your configuration:
- Total OCPUs across all A1.Flex instances ≤ 4
- Total memory across all A1.Flex instances ≤ 24 GB
- Total storage (boot + block) ≤ 200 GB

### Image not found

Ensure `os_version` matches available Ubuntu versions (22.04, 24.04, etc.)

### VCN/Subnet conflicts

Check that CIDR blocks don't overlap with existing networks in your compartment.
