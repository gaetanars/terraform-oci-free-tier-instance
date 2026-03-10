# Complete Example

This example demonstrates all available features of the OCI Free Tier Instance module.

## What This Creates

- **VCN**: Virtual Cloud Network with custom CIDR
- **Subnet**: Public subnet
- **Internet Gateway**: For internet access
- **Route Table**: With route to Internet Gateway
- **Security List**: SSH + ICMP + HTTP + HTTPS rules
- **Network Security Group (NSG)**: Modern alternative with custom port 8080 rule
- **Compute Instance**: VM.Standard.A1.Flex with custom resources
- **Reserved Public IP**: Persistent IP address (survives instance restart)
- **Block Volume**: 50GB additional storage with bronze backup policy
- **Boot Volume Backup**: Bronze backup policy for boot volume
- **Cloud-init**: Custom initialization script

## Features Demonstrated

1. **Full Network Stack**: VCN, subnet, IGW, route table
2. **Reserved Public IP**: Persistent IP with destroy protection
3. **Security Lists**: Traditional firewall rules
4. **Network Security Groups**: Modern firewall alternative
5. **Block Volumes**: Additional storage with backups
6. **Backup Policies**: Automated backups for boot and block volumes
7. **Cloud-init**: Server initialization with templates
8. **Tags**: Resource organization
9. **SSH Restrictions**: Security best practices

## Network Mode

This example uses **Full Stack** mode with all advanced features enabled.

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

6. Connect to your instance:
   ```bash
   terraform output ssh_command
   ```

## Block Volume Usage

After the instance is running, you'll need to format and mount the block volume:

```bash
# SSH into the instance
ssh ubuntu@<instance-public-ip>

# Find the block volume device
lsblk

# Format the volume (usually /dev/sdb)
sudo mkfs.ext4 /dev/sdb

# Create mount point
sudo mkdir -p /mnt/data

# Mount the volume
sudo mount /dev/sdb /mnt/data

# Add to /etc/fstab for automatic mounting
echo '/dev/sdb /mnt/data ext4 defaults 0 2' | sudo tee -a /etc/fstab
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Note: If `prevent_public_ip_destroy = true`, you'll need to set it to `false` first or manually remove the reserved IP from the state before destroying.

## Estimated Cost

**Free** - All resources are within Oracle Cloud Always Free tier limits:
- VM.Standard.A1.Flex: Up to 4 OCPUs and 24GB RAM (total across all instances)
- Boot volume: Up to 200GB
- Block volumes: Up to 200GB total
- Backup policies: Bronze tier included in Always Free
