# UniFi Network Server Example

This example demonstrates how to deploy UniFi OS Server on Oracle Cloud Free Tier using the module.

This is the **migration example** showing how the original `terraform/` code has been refactored to use the reusable module.

## What This Creates

- **Complete UniFi Network infrastructure**:
  - VCN with Internet Gateway
  - Public subnet with route table
  - Security list with all UniFi ports configured
  - VM.Standard.A1.Flex instance (ARM64)
  - Reserved public IP (persistent)
  - UniFi OS Server installed via cloud-init

## UniFi Ports Configuration

All UniFi ports can be individually enabled/disabled via variables:

| Port | Protocol | Variable | Description | Default |
|------|----------|----------|-------------|---------|
| 22 | TCP | `allowed_ssh_cidrs` | SSH access | 0.0.0.0/0 |
| 80 | TCP | `enable_port_http` | HTTP (Let's Encrypt) | false |
| 3478 | UDP | `enable_port_stun` | STUN Discovery | true |
| 5005 | TCP | `enable_port_unifi_5005` | Unknown | false |
| 5514 | UDP | `enable_port_remote_logging` | Remote Syslog | false |
| 6789 | TCP | `enable_port_mobile_speedtest` | Mobile Speed Test | true |
| 8080 | TCP | `enable_port_device_adoption` | Device Adoption | true |
| 8443 | TCP | `enable_port_https_portal` | Web UI (Console) | true |
| 8843 | TCP | `enable_port_https_guest_portal` | Guest Portal HTTPS | true |
| 8444 | TCP | `enable_port_secure_portal` | Hotspot Secure Portal | true |
| 8880 | TCP | `enable_port_hotspot_8880` | Hotspot Redirect | true |
| 8881 | TCP | `enable_port_hotspot_8881` | Hotspot Redirect | true |
| 8882 | TCP | `enable_port_hotspot_8882` | Hotspot Redirect | false |
| 9543 | TCP | `enable_port_unifi_9543` | Unknown | false |
| 10001 | UDP | `enable_port_device_discovery` | Device Discovery | true |
| 10003 | UDP | `enable_port_unifi_10003` | Unknown | false |
| 11084 | TCP | `enable_port_unifi_11084` | Unknown | false |
| 11443 | TCP | `enable_port_websockets` | Remote Management | true |

Most UniFi ports are restricted to `allowed_unifi_cidrs` for security.

## Security Recommendations

1. **Restrict SSH access**:
   ```hcl
   allowed_ssh_cidrs = ["YOUR_IP/32"]
   ```

2. **Restrict UniFi ports**:
   ```hcl
   allowed_unifi_cidrs = ["YOUR_NETWORK/24"]
   ```

3. **Enable only required ports**:
   - After initial setup, disable port 11443 if using UniFi OS Server app
   - Disable unknown ports (5005, 9543, 10003, 11084) unless needed

## Usage

1. Copy the example tfvars file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your values

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Plan the deployment:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

6. Get the UniFi web interface URL:
   ```bash
   terraform output unifi_web_ui
   ```

## Post-Deployment

1. **Access UniFi Setup**:
   - Navigate to `https://<instance_public_ip>:8443` or `:11443`
   - Accept the self-signed certificate warning
   - Follow the UniFi setup wizard

2. **Optional: Setup Let's Encrypt SSL**:
   - Set `enable_port_http = true` to allow HTTP-01 challenge
   - Configure a domain name pointing to your instance
   - Use the `unifi_easy_encrypt` variables to automate SSL setup

3. **Optional: Setup Dynamic DNS**:
   - Configure `ddclient_*` variables
   - Automatically update DNS when IP changes

## Migration from Original Code

This example shows how the original `terraform/` code has been migrated to use the module:

**Before** (terraform/compute.tf, network.tf, data.tf):
- Manual resource definitions
- ~350 lines of code
- Hardcoded UniFi-specific logic

**After** (this example):
- Single module call
- ~100 lines of code (mostly locals for port rules)
- Reusable across projects

The migration preserves all functionality while making the code:
- More maintainable
- Reusable for other projects
- Easier to understand

## Estimated Cost

**Free** - All resources are within Oracle Cloud Always Free tier limits.

## Troubleshooting

1. **Instance not accessible**:
   - Check security list rules
   - Verify public IP is attached
   - Check `allowed_ssh_cidrs` and `allowed_unifi_cidrs`

2. **UniFi not starting**:
   - SSH into instance
   - Check cloud-init logs: `sudo tail -f /var/log/cloud-init-output.log`
   - Check UniFi logs: `sudo journalctl -u unifi`

3. **Let's Encrypt fails**:
   - Ensure port 80 is open (`enable_port_http = true`)
   - Verify domain points to instance IP
   - Check DNS propagation
