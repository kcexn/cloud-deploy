# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Kubernetes cluster deployment automation system** that uses Terraform for infrastructure provisioning and Ansible for Kubernetes component configuration on Google Cloud Platform (GCP). The system deploys production-ready Kubernetes clusters with multi-master high availability architecture.

## Common Commands

### Install Dependencies
```bash
ansible-galaxy install -r requirements.yml
```

### Complete Deployment Workflow
```bash
# 1. Deploy infrastructure with Terraform
cd terraform/environments/development
terraform init
terraform plan
terraform apply

# 2. Sync Ansible inventory with Terraform outputs
cd ../../..
./scripts/sync_inventory.sh development

# 3. Configure Kubernetes components on all nodes
ansible-playbook playbooks/site.yml

# 4. Initialize Kubernetes cluster (manual step after Ansible completes)
# SSH to a controller node and run:
# sudo kubeadm init --config=/etc/kubernetes/kubeadm-config.yaml
```

### Terraform Infrastructure Management

#### Deploy Infrastructure
```bash
# Development environment
cd terraform/environments/development
terraform init
terraform plan
terraform apply

# Production environment
cd terraform/environments/production
terraform init
terraform plan
terraform apply

# With custom variables
terraform apply -var="machine_type=e2-standard-2"
```

#### Destroy Infrastructure
```bash
# Development environment
cd terraform/environments/development
terraform destroy

# Production environment
cd terraform/environments/production
terraform destroy
```

#### Terraform State Management
```bash
# View current state
terraform show

# List resources in state
terraform state list

# Import existing resources (if needed)
terraform import google_compute_instance.instances["dev-controller-01"] projects/PROJECT_ID/zones/ZONE/instances/INSTANCE_NAME

# Validate configuration
terraform validate
terraform fmt
```

### Ansible Configuration Management

#### Configure All Servers
```bash
# Configure all servers (after infrastructure is deployed)
ansible-playbook playbooks/site.yml

# Configure specific node groups
ansible-playbook playbooks/site.yml --limit controller
ansible-playbook playbooks/site.yml --limit worker
```

#### Inventory Management
```bash
# Sync inventory after Terraform deployment
./scripts/sync_inventory.sh development
./scripts/sync_inventory.sh production

# Test inventory connectivity
ansible all -i inventory/hosts.yml -m ping --limit development
```

### Validation and Testing
```bash
# Validate playbook syntax
ansible-playbook --syntax-check playbooks/site.yml

# Dry run (check mode)
ansible-playbook playbooks/site.yml --check

# Test SSH connectivity
ansible all -m ping --limit development
```

## Architecture Overview

### Dual-Stack Infrastructure Management
- **Terraform**: Infrastructure provisioning (VMs, networking, firewall rules)
- **Ansible**: Kubernetes component configuration (containerd, kubeadm, kubelet, kubectl)
- **Python Scripts**: Inventory synchronization between Terraform and Ansible

### Technology Stack
- **Cloud Provider**: Google Cloud Platform (GCP)
- **Container Runtime**: containerd v2.1.3
- **Kubernetes**: v1.33 (kubeadm, kubelet, kubectl)
- **Operating System**: Debian 12 (Bookworm)
- **Infrastructure as Code**: Terraform
- **Configuration Management**: Ansible

### Node Architecture
- **Controller Nodes**: 3 nodes for high availability (etcd quorum)
- **Worker Nodes**: 3 nodes for workload distribution
- **Network**: Private subnets with NAT gateway for internet access
- **Zones**: Multi-zone deployment (australia-southeast1-a/b/c)

### Kubernetes Components Installed
- **containerd**: Container runtime with proper CNI configuration
- **kubeadm**: Kubernetes cluster initialization tool
- **kubelet**: Node agent for pod management
- **kubectl**: Command-line tool for cluster management
- **System Configuration**: IP forwarding, bridge networking, required kernel modules

### Network Configuration
- **VPC**: Custom VPC with private subnets per zone
- **Subnets**: 
  - Controllers: 10.152.1.0/24 (zone-a), 10.152.2.0/24 (zone-b), 10.152.3.0/24 (zone-c)
  - Workers: 10.152.4.0/24 (zone-a), 10.152.5.0/24 (zone-b), 10.152.6.0/24 (zone-c)
- **Firewall**: SSH (22), HTTP (80), HTTPS (443), ICMP, and internal cluster communication

### Variable Hierarchy
1. **Global**: `inventory/group_vars/all.yml` - Kubernetes versions, common packages
2. **Environment**: `inventory/group_vars/{development,production}.yml` - environment-specific settings
3. **Role Defaults**: `roles/*/defaults/main.yml` - component-specific versions and configurations
4. **Terraform Variables**: `terraform/environments/*/terraform.tfvars` - infrastructure settings

## Working with This Repository

### Prerequisites
1. **Terraform**: Version 1.12+ installed
2. **Ansible**: Version 2.9+ installed
3. **Python**: Version 3.8+ with PyYAML
4. **GCP Credentials**: Service account with Compute Engine and VPC permissions
5. **SSH Keys**: Configured for GCP OS Login or local key-based authentication

### Before Deployment
1. **Configure GCP Project**: Set `gcp_project` in environment group_vars
2. **Set Service Account**: Configure `gcp_service_account_file` path
3. **Check Terraform Variables**: Review `terraform/environments/*/terraform.tfvars`
4. **Validate Inventory**: Ensure group_vars match your requirements

### Environment Structure
- **Development**: 6 VMs (3 controllers + 3 workers) in Australia Southeast region
- **Production**: Minimal configuration (only basic variables defined)

### Deployment Process
1. **Infrastructure**: Terraform creates VMs, networks, and firewall rules
2. **Inventory Sync**: Python script generates Ansible inventory from Terraform outputs
3. **Configuration**: Ansible installs and configures Kubernetes components
4. **Cluster Init**: Manual kubeadm init on controller nodes (not automated)

### Post-Deployment Manual Steps
After Ansible completes, manually initialize the Kubernetes cluster:
```bash
# SSH to any controller node
# Run kubeadm init with the generated config
sudo kubeadm init --config=/etc/kubernetes/kubeadm-config.yaml

# Configure kubectl for root user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install CNI plugin (e.g., Calico, Flannel)
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.0/manifests/calico.yaml
```

### Security Considerations
- **Private Networking**: No external IP addresses on instances
- **NAT Gateway**: Controlled internet access for package downloads
- **OS Login**: GCP OS Login integration for SSH access
- **Service Account**: Minimal permissions for GCP API access
- **Firewall Rules**: Restrictive rules with specific port access

### Key Files and Their Purposes
- **`terraform/modules/gcp-infrastructure/`**: Reusable Terraform module for GCP resources
- **`scripts/generate_inventory.py`**: Converts Terraform outputs to Ansible inventory
- **`roles/containerd/`**: Container runtime installation and configuration
- **`roles/kubeadm/`**: Kubernetes components installation
- **`roles/common/`**: Basic system configuration and packages

### Limitations
- **GCP Only**: Currently only supports Google Cloud Platform
- **Manual Cluster Init**: Kubernetes cluster initialization requires manual intervention
- **No CNI Installation**: Container Network Interface must be installed manually
- **No Monitoring**: No built-in monitoring or logging configuration
