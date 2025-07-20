# k8s-deploy

Comprehensive Kubernetes platform deployment automation using Terraform and Ansible on Google Cloud Platform.

## Overview

This project provides automated deployment of highly-available Kubernetes clusters on GCP using a modern infrastructure-as-code approach. It combines Terraform for infrastructure provisioning with Ansible for Kubernetes component configuration, delivering production-ready clusters with multi-master architecture, including service mesh, serverless computing, CI/CD pipelines, and GitOps capabilities.

## Features

- **High Availability**: 3-node controller setup with etcd quorum
- **Multi-Zone Deployment**: Distributes nodes across GCP zones for resilience  
- **Private Networking**: Secure private subnets with NAT gateway for internet access
- **Global Load Balancing**: TCP proxy load balancer with HTTP to NodePort forwarding
- **Modern Container Runtime**: containerd v2.1.3 with proper CNI configuration
- **Latest Kubernetes**: v1.33 with kubeadm, kubelet, and kubectl
- **Network Plugin**: Calico v3.30.2 for pod networking and security policies
- **Service Mesh**: Istio ambient mesh for traffic management and security
- **Serverless Platforms**: Knative and OpenWhisk for event-driven workloads
- **CI/CD Pipeline**: Tekton for cloud-native continuous integration/delivery
- **GitOps**: ArgoCD for declarative configuration management
- **Database**: CouchDB for serverless application data persistence
- **TLS Management**: Automated self-signed certificate generation and management
- **Infrastructure as Code**: Terraform state management with environment isolation
- **Automated Configuration**: Ansible roles for consistent node setup
- **Inventory Synchronization**: Automatic sync between Terraform and Ansible

## Architecture

### Infrastructure Components
- **Current Deployment**: 1 controller node + 3 worker nodes (designed for 3+3 HA setup)
- **Zone Deployment**: Single zone (australia-southeast1-a) instead of multi-zone
- **Private Networking**: 10.152.0.0/20 CIDR with zone-specific subnets
- **Security**: Firewall rules for SSH, HTTP, HTTPS, and cluster communication

### Technology Stack
- **Cloud Provider**: Google Cloud Platform (GCP)
- **Infrastructure**: Terraform v1.12+
- **Configuration**: Ansible v2.9+
- **Container Runtime**: containerd v2.1.3
- **Kubernetes**: v1.33 (kubeadm, kubelet, kubectl)
- **Operating System**: Debian 12 (Bookworm)
- **Network Plugin**: Calico v3.30.2
- **Load Balancing**: Global TCP Proxy Load Balancer (HTTP to NodePort)
- **Service Mesh**: Istio (ambient mesh)
- **Serverless Platforms**: Knative, OpenWhisk
- **CI/CD**: Tekton Pipelines
- **GitOps**: ArgoCD
- **Database**: CouchDB (for serverless applications)
- **TLS Management**: Self-signed certificates

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

6. **Deploy Additional Platform Components** (Optional):
   ```bash
   # Deploy ArgoCD for GitOps
   ansible-playbook playbooks/argocd.yml
   
   # Deploy Knative for serverless
   ansible-playbook playbooks/knative.yml
   
   # Deploy Tekton for CI/CD
   ansible-playbook playbooks/tekton.yml
   
   # Deploy OpenWhisk for event-driven serverless
   ansible-playbook playbooks/openwhisk.yml
   ```

7. **Validate Deployment**:
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
│   ├── kubernetes.yml        # Main Kubernetes configuration playbook
│   ├── argocd.yml            # ArgoCD GitOps deployment
│   ├── knative.yml           # Knative serverless platform
│   ├── tekton.yml            # Tekton CI/CD pipelines
│   ├── openwhisk.yml         # OpenWhisk serverless platform
│   ├── files/                # Static configuration files
│   ├── tasks/                # Shared task files
│   └── templates/            # Jinja2 templates
├── roles/                    # Ansible roles
│   ├── common/               # Basic system configuration
│   ├── containerd/           # Container runtime setup
│   ├── kubernetes/           # Kubernetes components (kubeadm, kubelet, kubectl)
│   ├── calico/               # Calico CNI network plugin
│   ├── argocd/               # ArgoCD GitOps deployment
│   ├── istio/                # Istio service mesh
│   ├── knative/              # Knative serverless platform
│   ├── tekton/               # Tekton CI/CD pipelines
│   ├── openwhisk/            # OpenWhisk serverless platform
│   ├── couchdb/              # CouchDB database
│   └── tls/                  # TLS certificate management
├── scripts/
│   └── generate_inventory.py # Terraform to Ansible inventory sync
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
- **Development**: `inventory/group_vars/development.yml` - Currently 1+3 nodes (designed for 3+3 HA)
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

**Note**: The `terraform.tfvars` file defines actual node counts. Current deployment is configured for 1 controller + 3 workers (designed for 3+3 HA setup).

## Network Configuration

- **VPC**: Custom VPC with regional subnets
- **Subnets**: 10.152.1.0/24, 10.152.2.0/24, 10.152.3.0/24
- **Internet Access**: NAT gateway for outbound connectivity
- **Security**: No external IP addresses on instances

## Load Balancer Configuration

The system includes a **Global TCP Proxy Load Balancer** that provides external HTTP access to Kubernetes services:

### Features
- **HTTP to NodePort Forwarding**: Terminates HTTP traffic on port 80 and forwards to configurable NodePort
- **Global External IP**: Provides a single external IP for worldwide access
- **Unmanaged Backend Service**: Uses CONNECTION-based load balancing across all node groups
- **Health Monitoring**: TCP health checks ensure only healthy nodes receive traffic
- **Automatic Firewall Rules**: Configures GCP load balancer IP ranges (35.191.0.0/16, 130.211.0.0/22)

### Configuration
Configure the NodePort service port in your environment's `terraform.tfvars`:
```hcl
nodeport_service_port = 30119  # Must be between 30000-32767
```

### Usage
1. Deploy a Kubernetes service with NodePort type on the configured port
2. Traffic to the load balancer's external IP on port 80 will be forwarded to all nodes
3. The service will be accessible from the internet via the load balancer IP

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

### Platform Component Deployment
```bash
# Deploy individual platform components
ansible-playbook playbooks/argocd.yml
ansible-playbook playbooks/knative.yml
ansible-playbook playbooks/tekton.yml
ansible-playbook playbooks/openwhisk.yml
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
ansible-playbook --syntax-check playbooks/argocd.yml
ansible-playbook --syntax-check playbooks/knative.yml
ansible-playbook --syntax-check playbooks/tekton.yml
ansible-playbook --syntax-check playbooks/openwhisk.yml

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
- **Single Zone**: Development environment uses single zone deployment
- **Self-Signed Certificates**: Uses self-signed TLS certificates (not production-ready)
- **No Monitoring**: Built-in monitoring and logging not included (Prometheus, Grafana, etc.)
- **No Backup Strategy**: Cluster backup and disaster recovery not automated
- **Minimal Scale**: Currently deployed as 1+3 nodes rather than designed 3+3 HA setup
