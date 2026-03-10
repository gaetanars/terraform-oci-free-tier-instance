# Existing Network Example

This example demonstrates how to use the module with an existing VCN and subnet.

## What This Creates

The example creates:
1. **VCN, subnet, IGW, route table** (simulating existing infrastructure)
2. **Compute Instance** using the module, attached to the existing subnet

In a real scenario, you would:
- Already have a VCN and subnet created
- Just pass their OCIDs to the module
- The module would only create the instance

## Network Mode

This example uses **Existing Network** mode:
- `vcn_id` is provided (existing VCN)
- `subnet_id` is provided (existing subnet)
- Result: Module only creates the instance, no network resources

## Usage Scenarios

### Scenario 1: VCN and Subnet Already Exist

If you already have a VCN and subnet, modify `main.tf`:

```hcl
module "oci_instance" {
  source = "../../"

  compartment_id = var.compartment_ocid
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))

  # Use your existing VCN and subnet OCIDs
  vcn_id    = "ocid1.vcn.oc1.eu-paris-1.example"
  subnet_id = "ocid1.subnet.oc1.eu-paris-1.example"

  # Optionally use existing security list
  security_list_ids = ["ocid1.securitylist.oc1.eu-paris-1.example"]

  display_name = "my-instance"
}
```

Remove the `oci_core_vcn` and `oci_core_subnet` resources from `main.tf`.

### Scenario 2: VCN Exists, Create New Subnet (Hybrid Mode)

If you have a VCN but want to create a new subnet. For public subnets, you **must** provide the existing IGW OCID so the module can add the default route to the new route table:

```hcl
module "oci_instance" {
  source = "../../"

  compartment_id = var.compartment_ocid
  ssh_public_key = file(pathexpand(var.ssh_public_key_path))

  # Use existing VCN, module will create subnet + route table
  vcn_id               = "ocid1.vcn.oc1.eu-paris-1.example"
  internet_gateway_id  = "ocid1.internetgateway.oc1.eu-paris-1.example"  # required for public subnet
  subnet_cidr_block    = "10.1.2.0/24"
  subnet_dns_label     = "newsubnet"

  display_name = "my-instance"
}
```

This is **Hybrid** mode: VCN exists, module creates subnet + route table + instance.

> **Note**: If `internet_gateway_id` is not provided and `subnet_type = "public"` (default), the created route table will have no default route and the instance won't have internet access.

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

6. Verify the module_info output shows "existing" mode:
   ```bash
   terraform output module_info
   ```

   Expected output:
   ```json
   {
     "network_mode" = "existing"
     ...
   }
   ```

## Benefits of Using Existing Network

1. **Shared Infrastructure**: Multiple instances can share the same VCN
2. **Pre-configured Security**: Use existing security lists and NSGs
3. **Network Isolation**: Deploy instances in different subnets of the same VCN
4. **Cost Efficiency**: Reuse existing network resources

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

This will destroy the instance and the example VCN/subnet (if created by this example).

## Estimated Cost

**Free** - All resources are within Oracle Cloud Always Free tier limits.
