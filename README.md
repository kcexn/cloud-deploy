# k8s-deploy

Production-ready Kubernetes cluster deployment automation using Terraform and Ansible on Google Cloud Platform.

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
- **6 VMs**: 3 controller nodes + 3 worker nodes
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
   ansible-galaxy install -r requirements.yml
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
   ./scripts/sync_inventory.sh development
   ```

5. **Configure Kubernetes Components**:
   ```bash
   ansible-playbook playbooks/site.yml
   ```

6. **Initialize Kubernetes Cluster**:
   ```bash
   # SSH to any controller node
   sudo kubeadm init --config=/etc/kubernetes/kubeadm-config.yaml
   
   # Configure kubectl
   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config
   
   # Install CNI plugin (example: Calico)
   kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml
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
│   └── site.yml              # Main Ansible playbook
├── roles/                    # Ansible roles
│   ├── common/               # Basic system configuration
│   ├── containerd/           # Container runtime setup
│   └── kubeadm/              # Kubernetes components
├── scripts/
│   ├── generate_inventory.py # Terraform to Ansible inventory sync
│   └── sync_inventory.sh     # Inventory sync wrapper
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
- **Development**: `inventory/group_vars/development.yml` - 6 VMs in Australia Southeast
- **Production**: `inventory/group_vars/production.yml` - Minimal configuration

### Terraform Variables
Customize infrastructure in `terraform/environments/*/terraform.tfvars`:
- Node group configurations (controller/worker)
- Machine types and disk sizes
- Network CIDR ranges
- GCP region and zones

## Workflow

1. **Infrastructure Provisioning**: Terraform creates VMs, VPC, subnets, and firewall rules
2. **Inventory Generation**: Python script converts Terraform outputs to Ansible inventory
3. **System Configuration**: Ansible installs and configures Kubernetes components
4. **Cluster Initialization**: Manual kubeadm init to bootstrap the cluster
5. **CNI Installation**: Manual installation of Container Network Interface

## Network Configuration

- **VPC**: Custom VPC with regional subnets
- **Subnets**: 10.152.1.0/24, 10.152.2.0/24, 10.152.3.0/24
- **Internet Access**: NAT gateway for outbound connectivity
- **Security**: No external IP addresses on instances

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

# Test Ansible connectivity
ansible all -m ping --limit development

# Verify Kubernetes components
kubectl get nodes
kubectl get pods -A
```

## Security Considerations

- Private networking with no external IP addresses
- GCP OS Login integration for SSH access
- Service account with minimal required permissions
- Firewall rules restricted to necessary ports
- Encrypted communication between cluster components

## Limitations

- **GCP Only**: Currently supports Google Cloud Platform exclusively
- **Manual Cluster Init**: Kubernetes cluster initialization requires manual steps
- **No CNI Automation**: Container Network Interface must be installed manually
- **No Monitoring**: Built-in monitoring and logging not included
- **No Backup Strategy**: Cluster backup and disaster recovery not automated
