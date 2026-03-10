# Changelog

All notable changes to this module are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.0] - 2026-03-10

### Breaking Changes

- **`create_internet_gateway` is now required for public subnets in full-stack mode.**
  Previously, the Internet Gateway was created automatically whenever `subnet_type = "public"` and `vcn_id` was null. This implicit behavior has been removed: you must now set `create_internet_gateway = true` explicitly.

  **Migration:** add `create_internet_gateway = true` to any full-stack configuration that uses a public subnet.

  ```hcl
  # Before (v0.3.x)
  module "instance" {
    source         = "..."
    compartment_id = var.compartment_id
    ssh_public_key = file("~/.ssh/id_rsa.pub")
    # IGW was created automatically
  }

  # After (v0.4.0)
  module "instance" {
    source                  = "..."
    compartment_id          = var.compartment_id
    ssh_public_key          = file("~/.ssh/id_rsa.pub")
    create_internet_gateway = true  # now explicit
  }
  ```

### Added

- **`create_internet_gateway` variable** — explicit opt-in to create an Internet Gateway in the VCN (full-stack mode only). Mirrors the existing `create_nat_gateway` pattern.
- **`create_nat_gateway` now works with public subnets.** Previously it was a no-op when `subnet_type = "public"`. The NAT Gateway is now created regardless of subnet type and its OCID is exposed via the `nat_gateway_id` output, allowing it to be wired into external route tables for future private subnets.
- **New example `examples/public-nat/`** — demonstrates deploying a public instance alongside a pre-provisioned NAT Gateway in the same VCN.

### Fixed

- **NAT Gateway `defined_tags` bug** — the `oci_core_nat_gateway` resource was incorrectly passing `var.defined_tags` directly instead of using the null-safe pattern `length(var.defined_tags) > 0 ? var.defined_tags : null`, which could remove OCI auto-applied defined tags on apply.

### Changed

- Updated `create_nat_gateway` variable description to reflect that it now works independently of `subnet_type`.
- Updated `internet_gateway_id` variable description (hybrid mode clarification).
- Added `examples/private-nat` and `examples/public-nat` to the GitHub Actions CI validation matrix.

## [0.3.0] - 2025-XX-XX

- feat(network): add NAT Gateway support for private subnets

## [0.2.1] - 2025-XX-XX

- fix: use null defined_tags when empty to avoid removing OCI auto-tags

## [0.2.0] - 2025-XX-XX

- Initial public release with full-stack, hybrid, and existing network modes

## [0.1.0] - 2025-XX-XX

- Initial release
