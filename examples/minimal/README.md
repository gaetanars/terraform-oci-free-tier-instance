# Minimal Example

This example demonstrates the minimal configuration required to deploy an Oracle Cloud Free Tier instance using the module.

## What This Creates

- **VCN**: A new Virtual Cloud Network with CIDR `10.0.0.0/16`
- **Subnet**: A public subnet with CIDR `10.0.1.0/24`
- **Internet Gateway**: For internet access
- **Route Table**: With route to Internet Gateway
- **Security List**: Default rules (SSH restricted to `allowed_ssh_cidrs`, ICMP, allow all egress)
- **Compute Instance**: VM.Standard.A1.Flex (2 OCPUs, 12GB RAM, 50GB boot volume)
- **Public IP**: Ephemeral (temporary, changes on instance restart)

## Network Mode

This example uses **Full Stack** mode:
- `vcn_id = null` (default)
- `subnet_id = null` (default)
- Result: Creates VCN + subnet + IGW + route table + instance

## Usage

1. Copy the example tfvars file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your OCI credentials and compartment OCID

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
   # Get the SSH command from outputs
   terraform output ssh_command
   ```

## Customization

To customize this example, you can add variables to the module call in `main.tf`:

```hcl
module "oci_instance" {
  source = "../../"

  compartment_id = var.compartment_ocid
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))

  # Customize instance
  display_name           = "my-instance"
  instance_ocpus         = 4
  instance_memory_in_gbs = 24

  # Use reserved IP (persistent)
  public_ip_mode           = "reserved"
  reserved_ip_display_name = "my-reserved-ip"

  # SSH is closed by default — provide your IP
  allowed_ssh_cidrs = ["1.2.3.4/32"]
}
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## Estimated Cost

**Free** - All resources are within Oracle Cloud Always Free tier limits.
