# k8s-deploy

Multi-cloud infrastructure deployment automation using Ansible.

## Overview

This Ansible project provides automated deployment and management of cloud infrastructure across multiple cloud providers (AWS, Azure, GCP). It includes support for both deployment and destruction operations with environment-specific configurations.

## Features

- Multi-cloud support (AWS, Azure, GCP)
- Environment-specific configurations (development, production)
- Automated infrastructure provisioning and teardown
- Kubernetes cluster deployment capabilities
- Common server configurations and package management

## Requirements

- Ansible 2.9+
- Python 3.8+
- Cloud provider CLI tools (aws-cli, azure-cli, gcloud)
- Required Ansible collections (install with `ansible-galaxy install -r requirements.yml`)

## Quick Start

1. Install required collections:
   ```bash
   ansible-galaxy install -r requirements.yml
   ```

2. Configure your cloud credentials (see Cloud Provider Setup below)

3. Update inventory and variables in `inventory/` directory

4. Deploy infrastructure:
   ```bash
   ansible-playbook playbooks/cloud-site.yml -t deploy --extra-vars "provider=gcp target_group=development"
   ```

5. Destroy infrastructure:
   ```bash
   ansible-playbook playbooks/cloud-site.yml -t destroy --extra-vars "provider=gcp target_group=development"
   ```

## Directory Structure

```
├── inventory/
│   ├── group_vars/        # Group-specific variables
│   ├── host_vars/         # Host-specific variables
│   └── hosts.yml          # Inventory file
├── playbooks/             # Ansible playbooks
├── roles/                 # Ansible roles
│   ├── cloud-infrastructure/
│   ├── common/
│   ├── database/
│   └── webserver/
├── files/                 # Static files
├── templates/             # Jinja2 templates
├── ansible.cfg            # Ansible configuration
└── requirements.yml       # Required collections
```

## Cloud Provider Setup

### GCP
1. Create a service account with necessary permissions
2. Download the service account key file
3. Set variables in your group_vars:
   ```yaml
   gcp_project: your-project-id
   gcp_service_account_file: /path/to/service-account.json
   ```

### AWS
Configure AWS credentials using AWS CLI or environment variables.

### Azure
Configure Azure credentials using Azure CLI or environment variables.

## Usage

### Deploy Infrastructure
```bash
ansible-playbook playbooks/cloud-site.yml -t deploy --extra-vars "provider=<cloud_provider> target_group=<environment>"
```

### Destroy Infrastructure
```bash
ansible-playbook playbooks/cloud-site.yml -t destroy --extra-vars "provider=<cloud_provider> target_group=<environment>"
```

### Available Parameters
- `provider`: Cloud provider (aws, azure, gcp)
- `target_group`: Environment (development, production)
- `deployment_region`: Cloud region (defaults to us-east-1)

## Configuration

Edit files in `inventory/group_vars/` to customize:
- `all.yml`: Global variables
- `development.yml`: Development environment settings
- `production.yml`: Production environment settings
