# Terraform Infrastructure

This directory contains Terraform configurations for deploying cloud infrastructure that mirrors the existing Ansible setup.

## Structure

```
terraform/
├── modules/
│   └── gcp-infrastructure/     # Reusable GCP infrastructure module
├── environments/
│   ├── development/            # Development environment
│   └── production/             # Production environment
└── README.md
```

## Features

- **Private Subnet with NAT**: Instances have no external IP addresses and use NAT for internet access
- **Google Cloud Ops Agent**: Automatically installed via startup script
- **Firewall Rules**: SSH, HTTP, and HTTPS access configured
- **Multiple Environments**: Separate configurations for development and production
- **Modular Design**: Reusable module for consistent infrastructure

## Quick Start

1. **Initialize Terraform**:
   ```bash
   cd terraform/environments/development
   terraform init
   ```

2. **Plan Deployment**:
   ```bash
   terraform plan
   ```

3. **Deploy Infrastructure**:
   ```bash
   terraform apply
   ```

4. **Configure Servers** (after deployment):
   ```bash
   cd ../../../
   ansible-playbook playbooks/site.yml
   ```

## Configuration

### Variables

Key variables that can be customized:

- `gcp_project`: GCP project ID
- `region`: GCP region (default: us-east1)
- `machine_type`: Instance type (default: e2-micro)
- `subnet_cidr`: Subnet CIDR range
- `instances`: Map of instance configurations

### Environment Files

Each environment has its own `terraform.tfvars` file with environment-specific values:

- `development/terraform.tfvars`: Development environment settings
- `production/terraform.tfvars`: Production environment settings

## Comparison with Ansible

| Feature | Ansible | Terraform |
|---------|---------|-----------|
| State Management | Stateless | Stateful |
| Infrastructure Drift | Manual detection | Automatic detection |
| Resource Dependencies | Manual ordering | Automatic dependency graph |
| Parallel Execution | Limited | Extensive |
| Resource Import | Not supported | Supported |
| Plan/Preview | Check mode only | Built-in planning |

## Migration from Ansible

To migrate from existing Ansible-managed infrastructure:

1. **Import existing resources**:
   ```bash
   terraform import google_compute_instance.instances["dev-01"] projects/PROJECT_ID/zones/ZONE/instances/INSTANCE_NAME
   ```

2. **Verify state alignment**:
   ```bash
   terraform plan
   ```

3. **Apply any necessary changes**:
   ```bash
   terraform apply
   ```

## Best Practices

1. **Always run `terraform plan`** before applying changes
2. **Use separate state files** for different environments
3. **Store state remotely** for team collaboration (GCS backend recommended)
4. **Version control** all `.tf` files
5. **Use `.tfvars` files** for environment-specific values