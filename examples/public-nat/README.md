# Example: Public Subnet with NAT Gateway

Creates an OCI instance in a **public subnet** with both an **Internet Gateway** and a **NAT Gateway** provisioned in the same VCN.

## Architecture

```
VCN (10.0.0.0/16)
├── Internet Gateway  ← route table default route (0.0.0.0/0)
├── NAT Gateway       ← not in this route table; use nat_gateway_id
│                        output to wire it for future private subnets
└── Route Table (0.0.0.0/0 → Internet Gateway)
    └── Public Subnet (10.0.1.0/24)
        └── Instance (ephemeral public IP)
```

## Use case

- Instance is publicly accessible (SSH, web services, etc.)
- NAT Gateway is pre-provisioned in the VCN alongside the Internet Gateway
- No network changes needed when adding private subnets later — simply create
  a new route table that routes `0.0.0.0/0` to the `nat_gateway_id` output

## Usage

```hcl
module "instance" {
  source = "../../"

  compartment_id = var.compartment_ocid
  ssh_public_key = file("~/.ssh/id_rsa.pub")

  # Public subnet (default) with NAT Gateway also provisioned
  create_nat_gateway = true

  allowed_ssh_cidrs = ["1.2.3.4/32"]
}
```

## Difference from private-nat example

| | public-nat | private-nat |
|---|---|---|
| `subnet_type` | `public` | `private` |
| `public_ip_mode` | `ephemeral` | `none` |
| Route table default route | Internet Gateway | NAT Gateway |
| NAT GW in route table | No (IGW owns `0.0.0.0/0`) | Yes |
| Instance reachable from internet | Yes | No |
