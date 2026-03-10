# Example: Private Subnet with NAT Gateway

Creates an OCI instance in a **private subnet** with a **NAT Gateway** for outbound internet access.

## Architecture

```
VCN (10.0.0.0/16)
└── NAT Gateway (public IP managed by OCI)
└── Route Table (0.0.0.0/0 → NAT Gateway)
└── Private Subnet (10.0.1.0/24)
    └── Instance (private IP only, no public IP)
```

## Use case

- Instance can reach the internet (package updates, API calls, etc.)
- Internet cannot reach the instance directly
- Access via OCI Bastion, VPN, or OCI Cloud Shell

## Usage

```hcl
module "instance" {
  source = "../../"

  compartment_id = var.compartment_ocid
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  subnet_type        = "private"
  public_ip_mode     = "none"
  create_nat_gateway = true
}
```

## Hybrid mode (existing VCN)

If you already have a VCN with a NAT Gateway:

```hcl
module "instance" {
  source = "../../"

  compartment_id = var.compartment_ocid
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  vcn_id         = "ocid1.vcn.oc1...."
  subnet_type    = "private"
  public_ip_mode = "none"
  nat_gateway_id = "ocid1.natgateway.oc1...."
}
```
