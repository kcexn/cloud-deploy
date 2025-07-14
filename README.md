# cloud-deploy

Production-ready cluster deployment automation using Terraform and Ansible on Google Cloud Platform.

## Overview

This project provides automated deployment of highly-available Kubernetes clusters on GCP using a modern infrastructure-as-code approach. It combines Terraform for infrastructure provisioning with Ansible for Kubernetes component configuration, delivering production-ready clusters with multi-master architecture.

## Features

- **High Availability**: 3-node controller setup with etcd quorum
- **Multi-Zone Deployment**: Distributes nodes across GCP zones for resilience
- **Private Networking**: Secure private subnets with NAT gateway for internet access
- **Modern Container Runtime**: containerd v2.1.3 with proper CNI configuration
- **Latest Kubernetes**: v1.33 with kubeadm, kubelet, and kubectl
- **Infrastructure as Code**: Terraform state management with environment isolation
- **Automated Configuration**: Ansible roles for consistent node setup
- **Inventory Synchronization**: Automatic sync between Terraform and Ansible

## Architecture

### Infrastructure Components
- **Current Deployment**: 1 controller node + 1 worker node (designed for 3+3 HA setup)
- **Multi-Zone**: australia-southeast1-a/b/c distribution
- **Private Networking**: 10.152.0.0/20 CIDR with zone-specific subnets
- **Security**: Firewall rules for SSH, HTTP, HTTPS, and cluster communication

### Technology Stack
- **Cloud Provider**: Google Cloud Platform (GCP)
- **Infrastructure**: Terraform v1.12+
- **Configuration**: Ansible v2.9+
- **Container Runtime**: containerd v2.1.3
- **Kubernetes**: v1.33 (kubeadm, kubelet, kubectl)
- **Operating System**: Debian 12 (Bookworm)

## Requirements

- Terraform 1.12+
- Ansible 2.9+
- Python 3.8+ with PyYAML
- GCP service account with Compute Engine and VPC permissions
- SSH access configuration (GCP OS Login or key-based)

## Quick Start

1. **Install Dependencies**:
   ```bash
   # Install required Ansible collections
   ansible-galaxy install -r requirements.yml
   
   # Install Python dependencies
   pip3 install PyYAML
   
   # Setup vault password file (optional)
   echo "your-vault-password" > .vault_pass
   chmod 600 .vault_pass
   ```

2. **Configure GCP Credentials**:
   - Create a GCP service account with necessary permissions
   - Download the service account key file
   - Update `inventory/group_vars/development.yml` with your project details

3. **Deploy Infrastructure**:
   ```bash
   cd terraform/environments/development
   terraform init
   terraform plan
   terraform apply
   ```

4. **Sync Inventory**:
   ```bash
   cd ../../..
   python3 scripts/generate_inventory.py terraform/environments/development
   ```

5. **Configure Kubernetes Components**:
   ```bash
   ansible-playbook playbooks/kubernetes.yml
   ```

6. **Validate Deployment**:
   ```bash
   kubectl get nodes
   kubectl get pods -A
   kubectl cluster-info
   ```

## Directory Structure

```
├── terraform/
│   ├── environments/          # Per-environment Terraform configurations
│   │   ├── development/       # Development environment
│   │   └── production/        # Production environment
│   └── modules/
│       └── gcp-infrastructure/  # Reusable GCP infrastructure module
├── inventory/
│   ├── group_vars/           # Environment and group variables
│   ├── host_vars/            # Host-specific variables
│   └── hosts.yml             # Generated inventory file
├── playbooks/
│   ├── site.yml              # Basic system setup playbook (common role)
│   └── kubernetes.yml        # Main Kubernetes configuration playbook
├── roles/                    # Ansible roles
│   ├── common/               # Basic system configuration
│   ├── containerd/           # Container runtime setup
│   └── kubernetes/           # Kubernetes components (kubeadm, kubelet, kubectl)
├── scripts/
│   └── generate_inventory.py # Terraform to Ansible inventory sync
├── files/                    # Static configuration files
├── templates/                # Jinja2 templates
├── ansible.cfg               # Ansible configuration
└── requirements.yml          # Required Ansible collections
```

## Configuration

### GCP Setup
1. Create a service account with these permissions:
   - Compute Engine Admin
   - VPC Admin
   - Service Account User

2. Download the service account key and update `inventory/group_vars/development.yml`:
   ```yaml
   gcp_project: your-project-id
   gcp_service_account_file: /path/to/service-account.json
   ```

### Environment Configuration
- **Development**: `inventory/group_vars/development.yml` - Currently 1+1 nodes (designed for 3+3 HA)
- **Production**: `inventory/group_vars/production.yml` - Minimal configuration

### Ansible Vault
Sensitive data like bootstrap tokens are encrypted using Ansible Vault:
```bash
# Run playbooks with vault
ansible-playbook playbooks/kubernetes.yml --ask-vault-pass

# Or use a vault password file
ansible-playbook playbooks/kubernetes.yml --vault-password-file .vault_pass
```

### Terraform Variables
Customize infrastructure in `terraform/environments/*/terraform.tfvars`:
- Node group configurations (controller/worker)
- Machine types and disk sizes
- Network CIDR ranges
- GCP region and zones

**Note**: The `terraform.tfvars` file defines actual node counts. Current deployment is configured for 1 controller + 1 worker (designed for 3+3 HA setup).

## Network Configuration

- **VPC**: Custom VPC with regional subnets
- **Subnets**: 10.152.1.0/24, 10.152.2.0/24, 10.152.3.0/24
- **Internet Access**: NAT gateway for outbound connectivity
- **Security**: No external IP addresses on instances

## Advanced Usage

### Tag-based Deployment
```bash
# Deploy only container runtime
ansible-playbook playbooks/kubernetes.yml --tags containerd

# Deploy Kubernetes components only
ansible-playbook playbooks/kubernetes.yml --tags kubernetes,cluster,init

# Run validation only
ansible-playbook playbooks/kubernetes.yml --tags validate
```

### Debugging
```bash
# Debug Ansible execution
ansible-playbook playbooks/kubernetes.yml -vvv --limit controller

# Debug inventory generation
python3 scripts/generate_inventory.py terraform/environments/development --debug

# Debug Terraform state
terraform state show 'module.infrastructure.google_compute_instance.instances["dev-controller-01"]'
```

## Destruction

```bash
# Destroy infrastructure
cd terraform/environments/development
terraform destroy
```

## Troubleshooting

### Common Issues
- **Terraform state**: Ensure proper state management and locking
- **SSH connectivity**: Verify GCP OS Login or SSH key configuration
- **Ansible inventory**: Run sync script after Terraform changes
- **Kubernetes init**: Check kubeadm logs for initialization errors

### Validation Commands
```bash
# Test Terraform configuration
terraform validate
terraform plan
terraform fmt -check

# Test Ansible connectivity
ansible all -m ping --limit development
ansible controller -m ping
ansible worker -m ping

# Test inventory structure
ansible-inventory -i inventory/hosts.yml --list
ansible-inventory -i inventory/hosts.yml --graph

# Validate Ansible playbooks
ansible-playbook --syntax-check playbooks/kubernetes.yml
ansible-playbook --syntax-check playbooks/site.yml

# Verify Kubernetes components
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
kubectl get componentstatuses

# Validate container runtime
sudo systemctl status containerd
sudo /usr/local/bin/ctr version
```

## Security Considerations

- Private networking with no external IP addresses
- GCP OS Login integration for SSH access
- Service account with minimal required permissions
- Firewall rules restricted to necessary ports
- Encrypted communication between cluster components

## Limitations

- **GCP Only**: Currently supports Google Cloud Platform exclusively
- **No Monitoring**: Built-in monitoring and logging not included
- **No Backup Strategy**: Cluster backup and disaster recovery not automated
- **Minimal Scale**: Currently deployed as 1+1 nodes rather than designed 3+3 HA setup
