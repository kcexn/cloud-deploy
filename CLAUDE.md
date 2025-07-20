# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **comprehensive Kubernetes platform deployment automation system** that uses Terraform for infrastructure provisioning and Ansible for Kubernetes component configuration on Google Cloud Platform (GCP). The system deploys production-ready Kubernetes clusters with multi-master high availability architecture, including service mesh, serverless computing, CI/CD pipelines, and GitOps capabilities.

## Common Commands
### Prerequisites Setup
```bash
# Install required Ansible collections
ansible-galaxy install -r requirements.yml

# Install Python dependencies
pip3 install PyYAML

# Setup vault password file (optional)
echo "your-vault-password" > .vault_pass
chmod 600 .vault_pass
```

### Complete Deployment Workflow
```bash
# 1. Deploy infrastructure with Terraform
pushd terraform/environments/development
terraform init
terraform plan
terraform apply

# 2. Sync Ansible inventory with Terraform outputs
popd
python3 scripts/generate_inventory.py terraform/environments/development

# 3. Configure Kubernetes components on all nodes
ansible-playbook playbooks/kubernetes.yml

# 4. Join the redundant controllers to the control plane (if needed)
pushd terraform/environments/development
terraform plan -var="join_controllers=true"
terraform apply -var="join_controllers=true"

# 5. Validate cluster deployment
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
```

### Terraform Infrastructure Management

#### Deploy Infrastructure
```bash
# Development environment
pushd terraform/environments/development
terraform init
terraform plan
terraform apply

# With custom variables
terraform apply -var="machine_type=e2-standard-2"
```

#### Destroy Infrastructure
```bash
# Development environment
pushd terraform/environments/development
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

# Check configuration with JSON output
terraform validate -json
terraform fmt -check

# Configure remote state backend (if needed)
terraform init -backend-config="bucket=your-terraform-state-bucket"

# Debug state
terraform state show 'module.infrastructure.google_compute_instance.instances["dev-controller-01"]'
```

### Ansible Configuration Management

#### Configure All Servers
```bash
# Configure all servers (after infrastructure is deployed)
ansible-playbook playbooks/kubernetes.yml

# Configure specific node groups
ansible-playbook playbooks/kubernetes.yml --limit controller
ansible-playbook playbooks/kubernetes.yml --limit worker

# Run common setup only
ansible-playbook playbooks/site.yml

# Tag-based deployment (granular control)
ansible-playbook playbooks/kubernetes.yml --tags containerd
ansible-playbook playbooks/kubernetes.yml --tags kubernetes,cluster,init
ansible-playbook playbooks/kubernetes.yml --tags validate

# Deploy additional platform components
ansible-playbook playbooks/argocd.yml
ansible-playbook playbooks/knative.yml
ansible-playbook playbooks/tekton.yml
ansible-playbook playbooks/openwhisk.yml

# Debug deployment
ansible-playbook playbooks/kubernetes.yml -vvv --limit controller
```

#### Inventory Management
```bash
# Sync inventory after Terraform deployment
python3 scripts/generate_inventory.py terraform/environments/development

# Test inventory connectivity
ansible all -i inventory/hosts.yml -m ping

# Test inventory structure
ansible-inventory -i inventory/hosts.yml --list
ansible-inventory -i inventory/hosts.yml --graph

# Test group connectivity
ansible controller -i inventory/hosts.yml -m ping
ansible worker -i inventory/hosts.yml -m ping

# Debug inventory generation
python3 scripts/generate_inventory.py terraform/environments/development --debug
```

### Validation and Testing
```bash
# Validate playbook syntax
ansible-playbook --syntax-check playbooks/kubernetes.yml
ansible-playbook --syntax-check playbooks/site.yml
ansible-playbook --syntax-check playbooks/argocd.yml
ansible-playbook --syntax-check playbooks/knative.yml
ansible-playbook --syntax-check playbooks/tekton.yml
ansible-playbook --syntax-check playbooks/openwhisk.yml

# Dry run (check mode)
ansible-playbook playbooks/kubernetes.yml --check
ansible-playbook playbooks/site.yml --check

# Test SSH connectivity
ansible all -m ping --limit development

# Validate configuration files
python3 -c "import yaml; yaml.safe_load(open('inventory/hosts.yml'))"

# Validate Kubernetes cluster
kubectl get nodes
kubectl get pods -A
kubectl cluster-info
kubectl get componentstatuses

# Validate container runtime
sudo /usr/local/bin/ctr version
sudo /usr/local/sbin/runc --version
sudo /usr/local/bin/containerd config dump
sudo systemctl status containerd
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
- **Network Plugin**: Calico v3.30.2
- **Load Balancing**: Global TCP Proxy Load Balancer (HTTP to NodePort forwarding)
- **Service Mesh**: Istio (ambient mesh)
- **Serverless Platforms**: Knative, OpenWhisk
- **CI/CD**: Tekton Pipelines
- **GitOps**: ArgoCD
- **Database**: CouchDB (for serverless applications)
- **TLS Management**: Self-signed certificates

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
- **Calico**: CNI network plugin for pod networking
- **ArgoCD**: GitOps continuous deployment tool
- **Istio**: Service mesh for traffic management and security
- **Knative**: Serverless computing platform
- **Tekton**: CI/CD pipeline framework
- **OpenWhisk**: Event-driven serverless platform
- **CouchDB**: Document database for serverless applications
- **TLS Certificates**: Self-signed certificates for secure communication
- **System Configuration**: IP forwarding, bridge networking, required kernel modules

### Network Configuration
- **VPC**: Custom VPC with private subnets per zone
- **Subnets**: 
  - Controllers: 10.152.1.0/24 (zone-a), 10.152.2.0/24 (zone-b), 10.152.3.0/24 (zone-c)
  - Workers: 10.152.4.0/24 (zone-a), 10.152.5.0/24 (zone-b), 10.152.6.0/24 (zone-c)
- **Firewall**: SSH (22), HTTP (80), HTTPS (443), ICMP, and internal cluster communication

### Load Balancer Configuration (Optional)
- **Global TCP Proxy Load Balancer**: Terminates HTTP traffic on port 80 and forwards to NodePort (only deployed when `nodeport_service_port` is defined)
- **External Static IP**: Global external IP address for public access
- **Health Checks**: TCP health checks on NodePort service
- **Backend Services**: Unmanaged backend service with CONNECTION balancing mode
- **Instance Groups**: All node groups (controller and worker) included as backends
- **Firewall Rules**: Automatic rules for Google Cloud Load Balancer IP ranges (35.191.0.0/16, 130.211.0.0/22)
- **NodePort Configuration**: Set `nodeport_service_port` variable (30000-32767) to enable TCP proxy load balancer, or leave null to disable

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
- **Development**: Currently 1 controller + 1 worker (designed for 3+3 HA setup) in Australia Southeast region
- **Production**: Minimal configuration (only basic variables defined)

### Deployment Process
1. **Infrastructure**: Terraform creates VMs, networks, and firewall rules
2. **Inventory Sync**: Python script generates Ansible inventory from Terraform outputs
3. **Configuration**: Ansible installs and configures Kubernetes components

### Security Considerations
- **Private Networking**: No external IP addresses on instances
- **NAT Gateway**: Controlled internet access for package downloads
- **OS Login**: GCP OS Login integration for SSH access
- **Service Account**: Minimal permissions for GCP API access
- **Firewall Rules**: Restrictive rules with specific port access

### Key Files and Their Purposes
- **`terraform/modules/gcp-infrastructure/`**: Reusable Terraform module for GCP resources
- **`scripts/generate_inventory.py`**: Converts Terraform outputs to Ansible inventory
- **`roles/common/`**: Basic system configuration and packages
- **`roles/containerd/`**: Container runtime installation and configuration
- **`roles/kubernetes/`**: Kubernetes components installation (kubeadm, kubelet, kubectl)
- **`roles/calico/`**: Calico CNI network plugin installation and configuration
- **`roles/argocd/`**: ArgoCD GitOps deployment and configuration
- **`roles/istio/`**: Istio service mesh installation and configuration
- **`roles/knative/`**: Knative serverless platform installation
- **`roles/tekton/`**: Tekton CI/CD pipeline installation
- **`roles/openwhisk/`**: OpenWhisk serverless platform installation
- **`roles/couchdb/`**: CouchDB database installation and configuration
- **`roles/tls/`**: TLS certificate management and configuration
- **`playbooks/site.yml`**: Basic system setup playbook (common role only)
- **`playbooks/kubernetes.yml`**: Main Kubernetes configuration playbook
- **`playbooks/argocd.yml`**: ArgoCD deployment playbook
- **`playbooks/knative.yml`**: Knative deployment playbook
- **`playbooks/tekton.yml`**: Tekton deployment playbook
- **`playbooks/openwhisk.yml`**: OpenWhisk deployment playbook

### Ansible Vault Usage
This project uses Ansible Vault to encrypt sensitive data like bootstrap tokens:

```bash
# Encrypt a string value
echo "secret-value" | ansible-vault encrypt_string --stdin-name 'variable_name'

# Run playbooks with vault
ansible-playbook playbooks/kubernetes.yml --ask-vault-pass

# Or use a vault password file
ansible-playbook playbooks/kubernetes.yml --vault-password-file .vault_pass
```

**Vault variables are stored in:**
- `inventory/group_vars/development.yml` - Contains encrypted bootstrap tokens
- Bootstrap tokens use format: `[a-z0-9]{6}.[a-z0-9]{16}` (token_id.token_secret)

### Actual Deployment Scale
**Current Reality vs Design:**
- **Designed for**: 3 controllers + 3 workers (HA setup)
- **Currently deployed**: 1 controller + 3 workers (development setup)
- **Terraform config**: `terraform/environments/development/terraform.tfvars` defines actual node counts
- **Zone deployment**: Single zone (australia-southeast1-a) instead of multi-zone

### Limitations
- **GCP Only**: Currently only supports Google Cloud Platform
- **Single Zone**: Development environment uses single zone deployment
- **Self-Signed Certificates**: Uses self-signed TLS certificates (not production-ready)
- **No Monitoring**: No built-in monitoring or logging configuration (Prometheus, Grafana, etc.)
- **No Backup Strategy**: No automated backup for etcd or persistent data
