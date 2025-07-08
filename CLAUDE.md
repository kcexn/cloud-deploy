# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Commands

### Install Dependencies
```bash
ansible-galaxy install -r requirements.yml
```

### Deploy Infrastructure
```bash
# Deploy to development environment on GCP
ansible-playbook playbooks/cloud-site.yml -t deploy --extra-vars "provider=gcp target_group=development"

# Deploy to production environment
ansible-playbook playbooks/cloud-site.yml -t deploy --extra-vars "provider=gcp target_group=production"

# Deploy with custom region
ansible-playbook playbooks/cloud-site.yml -t deploy --extra-vars "provider=gcp target_group=development deployment_region=us-west1"

# Deploy with custom network (use existing VPC)
ansible-playbook playbooks/cloud-site.yml -t deploy --extra-vars "provider=gcp target_group=development network_name=default"

# Deploy with custom network using JSON
ansible-playbook playbooks/cloud-site.yml -t deploy --extra-vars "provider=gcp target_group=development" --extra-vars '{"vpc": {"selfLink": "https://www.googleapis.com/compute/v1/projects/PROJECT_ID/global/networks/NETWORK_NAME"}}'
```

### Destroy Infrastructure
```bash
# Destroy development environment
ansible-playbook playbooks/cloud-site.yml -t destroy --extra-vars "provider=gcp target_group=development"
```

## Terraform Infrastructure Management

### Prerequisites
```bash
# Install Terraform (if not already installed)
# Download from https://terraform.io/downloads or use package manager
terraform version
```

### Initialize Terraform
```bash
# Initialize development environment
cd terraform/environments/development
terraform init

# Initialize production environment
cd terraform/environments/production
terraform init
```

### Deploy Infrastructure with Terraform
```bash
# Deploy to development environment
cd terraform/environments/development
terraform plan
terraform apply

# Deploy to production environment
cd terraform/environments/production
terraform plan
terraform apply

# Deploy with custom variables
terraform apply -var="machine_type=e2-standard-2"
```

### Destroy Infrastructure with Terraform
```bash
# Destroy development environment
cd terraform/environments/development
terraform destroy

# Destroy production environment
cd terraform/environments/production
terraform destroy
```

### Terraform State Management
```bash
# View current state
terraform show

# List resources in state
terraform state list

# Import existing resources (if needed)
terraform import google_compute_instance.instances["dev-01"] projects/PROJECT_ID/zones/ZONE/instances/INSTANCE_NAME

# Validate configuration
terraform validate
terraform fmt
```

### Server Configuration
```bash
# Configure all servers (after infrastructure is deployed)
ansible-playbook playbooks/site.yml

# Configure specific server types
ansible-playbook playbooks/site.yml --limit "*-web-*"
ansible-playbook playbooks/site.yml --limit "*-db-*"
```

### Validation and Testing
```bash
# Validate playbook syntax
ansible-playbook --syntax-check playbooks/cloud-site.yml

# Dry run (check mode)
ansible-playbook playbooks/cloud-site.yml -t deploy --check --extra-vars "provider=gcp target_group=development"

# Test SSH connectivity after deployment
# SSH connectivity is automatically tested during deployment with proper key authentication
```

## Architecture Overview

### Dual-Playbook System
- **`playbooks/cloud-site.yml`**: Cloud infrastructure management (create/destroy VMs)
- **`playbooks/site.yml`**: Server configuration (post-deployment)

### Cloud Infrastructure Role
The system is designed for multi-cloud support but currently only implements GCP:
- **Provider Abstraction**: Uses `cloud_provider` variable to conditionally include provider-specific tasks
- **Asynchronous Operations**: Parallelizes VM creation for performance with 300-second timeout
- **Local Execution**: Cloud operations run on localhost with `connection: local`
- **Firewall Management**: Automatically creates/destroys firewall rules for SSH (22), HTTP (80), HTTPS (443), and ICMP
- **Network Flexibility**: Supports both VPC creation and existing network usage

### Variable Hierarchy
1. **Global**: `inventory/group_vars/all.yml` - SSH config, common packages
2. **Environment**: `inventory/group_vars/{development,production}.yml` - environment-specific settings
3. **Runtime**: Command-line `--extra-vars` parameters

### Key Design Patterns
- **Tag-based Control**: Uses `deploy`/`destroy` tags with `never` to prevent accidental execution
- **Environment Isolation**: Separate group_vars and inventory groups for each environment
- **Dynamic Loading**: Loads environment-specific variables at runtime based on `target_group`

## Working with This Repository

### Before Deployment
1. **Verify Prerequisites**: Ensure `gcp_project` and `gcp_service_account_file` are set in environment group_vars
2. **Check Inventory**: Confirm hosts exist in the target environment group in `inventory/hosts.yml`
3. **Validate Collections**: Run `ansible-galaxy install -r requirements.yml` if collections are missing

### Critical Parameters
- **`provider`**: Must be `gcp` (only implemented provider)
- **`target_group`**: Must match an environment group in inventory (`development`, `staging`, `production`)
- **`deployment_region`**: GCP region (defaults to `us-east-1`)
- **`network_name`**: Optional - specify existing network name (constructs VPC selfLink automatically)
- **`vpc`**: Optional - provide complete VPC object with selfLink for existing networks

### Cloud Provider Implementation Status
- **GCP**: Fully implemented with VPC and compute instance management
- **AWS**: Partial implementation exists in `playbooks/tasks/aws-deploy.yml`
- **Azure**: Framework exists but not implemented

### Host Inventory Structure
- **Development**: 3 hosts (dev-01, dev-02, dev-03) with zone distribution
- **Staging**: 2 hosts (web + db servers)
- **Production**: 4 hosts (2 web + 2 db servers)

### Async Operations and SSH Testing
GCP deployments use asynchronous operations:
- VMs are created in parallel with 300-second timeout
- Wait task polls every 5 seconds for up to 60 retries
- SSH connectivity is automatically tested post-deployment with proper key authentication
- Failed deployments may require manual cleanup

### Security Considerations
- **Ansible Vault**: Configured with `.vault_pass` file for sensitive data
- **SSH Keys**: Uses `ansible_ssh_private_key_file` variable (defaults to `~/.ssh/id_rsa`)
- **Service Account**: GCP authentication requires service account file
- **Firewall Rules**: Automatically managed with proper port restrictions (22, 80, 443, ICMP)
- **Network Security**: Supports both public (0.0.0.0/0) and restricted source ranges

### Limitations
- **No Rollback Strategy**: Failed deployments require manual cleanup
- **Placeholder Roles**: Webserver and database roles are empty
- **GCP Only**: Multi-cloud design but only GCP is implemented
- **Missing Staging Environment**: No staging.yml in group_vars directory

### Network Configuration Options
- **Default VPC Creation**: Creates new VPC when `vpc` variable is not defined
- **Existing Network Usage**: Use `network_name` parameter or full `vpc` object for existing networks
- **Firewall Port Configuration**: Configurable via `firewall_ports` variable in defaults/main.yml
- **Source Range Restrictions**: Configurable via `firewall_source_ranges` variable
