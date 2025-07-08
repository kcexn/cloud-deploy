# Ansible Inventory Synchronization

This document explains how to synchronize your Ansible inventory with Terraform infrastructure.

## Overview

The inventory synchronization system automatically generates Ansible inventory files from Terraform outputs, ensuring your inventory always matches your actual infrastructure.

## Components

1. **Terraform Outputs**: Enhanced outputs in the GCP infrastructure module that provide structured data
2. **Python Script**: `scripts/generate_inventory.py` - Generates inventory from Terraform outputs
3. **Bash Script**: `scripts/sync_inventory.sh` - Wrapper script for easy execution

## Usage

### Manual Synchronization

```bash
# Sync inventory for development environment
./scripts/sync_inventory.sh development

# Sync inventory for production environment
./scripts/sync_inventory.sh production
```

### Automated Synchronization

Add to your deployment workflow:

```bash
# After terraform apply
cd terraform/environments/development
terraform apply
cd ../../..
./scripts/sync_inventory.sh development
```

## Generated Inventory Structure

The generated inventory follows this structure:

```yaml
all:
  children:
    development:  # Environment name
      hosts:
        dev-controller-01:
          ansible_host: 10.152.1.10
          zone: australia-southeast1-a
          machine_type: e2-small
          disk_size_gb: 40
          disk_type: pd-balanced
          label_role: k8s
          label_tier: controller
        dev-worker-01:
          ansible_host: 10.152.2.11
          # ... more host variables
      children:
        controller:  # Node group name
          hosts:
            dev-controller-01: {}
            dev-controller-02: {}
            dev-controller-03: {}
          vars:
            group_labels:
              role: k8s
              tier: controller
            machine_type: e2-small
            disk_size_gb: 40
            disk_type: pd-balanced
        worker:  # Node group name
          hosts:
            dev-worker-01: {}
            dev-worker-02: {}
            dev-worker-03: {}
          vars:
            group_labels:
              role: k8s
              tier: worker
            machine_type: e2-medium
            disk_size_gb: 40
            disk_type: pd-standard
      vars:
        region: australia-southeast1
        environment: development
```

## Prerequisites

1. **Terraform Initialized**: Run `terraform init` in your environment directory
2. **Infrastructure Deployed**: Run `terraform apply` to create resources
3. **Python 3**: Required for the generation script
4. **PyYAML**: Install with `pip install PyYAML`

## Backup Strategy

The script automatically creates backups of your existing inventory:
- Original: `inventory/hosts.yml`
- Backup: `inventory/hosts.yml.backup`

## Integration with Deployment

### Option 1: Manual Integration
Run the sync script after each `terraform apply`:

```bash
cd terraform/environments/development
terraform apply
cd ../../..
./scripts/sync_inventory.sh development
```

### Option 2: Terraform Hook
Add to your `terraform apply` workflow:

```bash
terraform apply && ../../../scripts/sync_inventory.sh development
```

### Option 3: Ansible Playbook Integration
Create a deployment playbook that includes inventory sync:

```yaml
- name: Deploy infrastructure and sync inventory
  hosts: localhost
  tasks:
    - name: Apply Terraform
      terraform:
        project_path: "terraform/environments/development"
        state: present
    
    - name: Sync Ansible inventory
      command: ./scripts/sync_inventory.sh development
      args:
        chdir: "{{ playbook_dir }}"
```

## Troubleshooting

### Common Issues

1. **Terraform not initialized**:
   ```bash
   cd terraform/environments/development
   terraform init
   ```

2. **No terraform outputs**:
   ```bash
   terraform apply  # Deploy infrastructure first
   ```

3. **Missing ansible_inventory_data output**:
   - Ensure you've updated the module outputs
   - Run `terraform plan` to see if outputs need to be added

4. **Permission denied**:
   ```bash
   chmod +x scripts/sync_inventory.sh
   chmod +x scripts/generate_inventory.py
   ```

### Testing

Validate the generated inventory:

```bash
# Test inventory structure
ansible-inventory -i inventory/hosts.yml --list

# Test host connectivity
ansible all -i inventory/hosts.yml -m ping --limit development
```

## Customization

### Adding Custom Host Variables

Modify the `generate_inventory.py` script to include additional host variables from Terraform outputs.

### Changing Inventory Structure

Update the inventory generation logic in `generate_inventory.py` to match your preferred structure.

### Environment-Specific Customization

The script automatically adapts to different environments based on the Terraform outputs and node group configurations.