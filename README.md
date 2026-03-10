# Oracle Cloud Free Tier Instance Module

A universal, reusable Terraform module for deploying compute instances on Oracle Cloud Infrastructure (OCI) Always Free tier.

## Features

- **Always Free Compatible**: Validates resources stay within OCI Always Free limits
- **Flexible Network Modes**: Full stack (VCN + subnet + instance), hybrid, or existing network
- **Public IP Options**: Reserved (persistent), ephemeral (temporary), or none (private)
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

Uses existing VCN, creates new subnet:

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  compartment_id = var.compartment_id
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  vcn_id            = "ocid1.vcn.oc1...."
  subnet_cidr_block = "10.0.2.0/24"
}
```

## Public IP Modes

### Reserved IP (Recommended for Production)

Persistent IP that survives instance restarts and recreations:

```hcl
module "instance" {
  source = "./modules/oci-free-tier-instance"

  # ... required vars ...

  public_ip_mode              = "reserved"
  reserved_ip_display_name    = "my-reserved-ip"
  prevent_public_ip_destroy   = true  # Prevent accidental deletion
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
}
```

This creates:
- VCN with CIDR 10.0.0.0/16
- Public subnet 10.0.1.0/24
- VM.Standard.A1.Flex instance (2 OCPUs, 12GB RAM)
- Ephemeral public IP
- Security list with SSH + ICMP rules

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
  public_ip_mode              = "reserved"
  reserved_ip_display_name    = "my-ip"
  prevent_public_ip_destroy   = true

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

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `compartment_id` | OCID of compartment | `string` | - | yes |
| `ssh_public_key` | SSH public key content | `string` | - | yes |
| `display_name` | Instance display name | `string` | `"oci-instance"` | no |
| `instance_shape` | Instance shape | `string` | `"VM.Standard.A1.Flex"` | no |
| `instance_ocpus` | Number of OCPUs | `number` | `2` | no |
| `instance_memory_in_gbs` | Memory in GB | `number` | `12` | no |
| `boot_volume_size_in_gbs` | Boot volume size | `number` | `50` | no |
| `os_version` | Ubuntu version | `string` | `"24.04"` | no |
| `vcn_id` | Existing VCN OCID | `string` | `null` | no |
| `subnet_id` | Existing subnet OCID | `string` | `null` | no |
| `vcn_cidr_blocks` | VCN CIDR blocks | `list(string)` | `["10.0.0.0/16"]` | no |
| `subnet_cidr_block` | Subnet CIDR block | `string` | `"10.0.1.0/24"` | no |
| `public_ip_mode` | Public IP mode | `string` | `"ephemeral"` | no |
| `allowed_ssh_cidrs` | Allowed SSH CIDRs | `list(string)` | `["0.0.0.0/0"]` | no |
| `enable_icmp` | Enable ICMP | `bool` | `true` | no |
| `ingress_security_rules` | Custom ingress rules | `list(object)` | `[]` | no |
| `create_nsg` | Create NSG | `bool` | `false` | no |
| `nsg_rules` | NSG rules | `list(object)` | `[]` | no |
| `block_volumes` | Block volumes | `list(object)` | `[]` | no |
| `boot_volume_backup_policy` | Backup policy | `string` | `null` | no |

See [variables.tf](./variables.tf) for complete list and descriptions.

## Outputs

| Name | Description |
|------|-------------|
| `instance_id` | Instance OCID |
| `instance_public_ip` | Public IP address |
| `instance_private_ip` | Private IP address |
| `instance_state` | Instance state |
| `vcn_id` | VCN OCID |
| `subnet_id` | Subnet OCID |
| `ssh_command` | SSH command to connect |
| `module_info` | Module metadata |

See [outputs.tf](./outputs.tf) for complete list.

## Examples

See the [examples/](./examples/) directory:

- **[minimal/](./examples/minimal/)**: Minimal configuration (3 lines)
- **[complete/](./examples/complete/)**: All features demonstrated
- **[existing-network/](./examples/existing-network/)**: Using existing VCN/subnet
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
