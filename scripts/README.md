# Ansible Inventory Synchronization

This document explains how to synchronize your Ansible inventory with Terraform infrastructure.

## Overview

The inventory synchronization system automatically generates Ansible inventory files from Terraform outputs, ensuring your inventory always matches your actual infrastructure.

## Components

1. **Terraform Outputs**: Enhanced outputs in the GCP infrastructure module that provide structured data
2. **Python Script**: `scripts/generate_inventory.py` - Generates inventory from Terraform outputs

## Usage

### Using generate_inventory.py Directly

The core inventory generation script can be used directly:

```bash
# Generate inventory from development environment
python3 scripts/generate_inventory.py terraform/environments/development

# Generate inventory from production environment
python3 scripts/generate_inventory.py terraform/environments/production
```

**Script Parameters:**
- `terraform_environment_dir`: Path to the Terraform environment directory containing `main.tf`

**Script Behavior:**
- Reads Terraform outputs using `terraform output -json`
- Extracts `ansible_inventory_data` from the outputs
- Generates inventory structure with environment and node groups
- Writes to `inventory/hosts.yml` (overwrites existing file)
- Provides detailed error messages for troubleshooting


### Automated Synchronization

Add to your deployment workflow:

```bash
# After terraform apply
cd terraform/environments/development
terraform apply
cd ../../..
python3 scripts/generate_inventory.py terraform/environments/development
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

### Required Terraform Outputs

The script requires the following Terraform output in your environment configuration:

```hcl
output "ansible_inventory_data" {
  description = "Structured data for Ansible inventory generation"
  value = {
    env    = var.environment
    region = var.region
    hosts  = {
      for name, instance in module.infrastructure.instances : name => {
        ansible_host = instance.network_interface[0].network_ip
        zone        = instance.zone
        # Add additional host variables as needed
      }
    }
    groups = {
      for group_name, group in var.node_groups : group_name => {
        hosts = [
          for name, instance in module.infrastructure.instances : name
          if can(regex("^${coalesce(group.base_name, group_name)}", name))
        ]
        vars = {
          group_labels = group.labels
          machine_type = group.machine_type
          disk_size_gb = group.disk_size_gb
          disk_type    = group.disk_type
        }
      }
    }
  }
}
```

## Backup Strategy

The script overwrites the existing inventory file. To preserve your current inventory, create a backup manually:

```bash
cp inventory/hosts.yml inventory/hosts.yml.backup
```

## Integration with Deployment

### Option 1: Manual Integration
Run the inventory script after each `terraform apply`:

```bash
cd terraform/environments/development
terraform apply
cd ../../..
python3 scripts/generate_inventory.py terraform/environments/development
```

### Option 2: Terraform Hook
Add to your `terraform apply` workflow:

```bash
terraform apply && cd ../../.. && python3 scripts/generate_inventory.py terraform/environments/development
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
    
    - name: Generate Ansible inventory
      command: python3 scripts/generate_inventory.py terraform/environments/development
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
   chmod +x scripts/generate_inventory.py
   ```

5. **Python script errors**:
   - **ImportError**: Install PyYAML with `pip install PyYAML`
   - **terraform command not found**: Ensure Terraform is installed and in PATH
   - **JSON decode error**: Check Terraform output format with `terraform output -json`

6. **Script usage errors**:
   ```bash
   # Correct usage
   python3 scripts/generate_inventory.py terraform/environments/development
   
   # Common mistakes
   python3 scripts/generate_inventory.py development  # Missing terraform/ prefix
   python3 scripts/generate_inventory.py terraform/environments/development/main.tf  # Don't specify file
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