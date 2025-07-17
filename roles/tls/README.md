# TLS Role

This Ansible role generates self-signed TLS certificates for Kubernetes cluster components.

## Purpose

The TLS role provides secure communication capabilities by:
- Creating required certificate and key directories
- Installing necessary dependencies (Python cryptography library)
- Generating private keys and self-signed certificates
- Configuring proper file permissions and ownership

## Requirements

- Python 3.x
- Ansible 2.9+
- Community.crypto collection

## Role Variables

### Certificate Configuration
- `tls_cert_path`: Certificate storage path (default: `/etc/ssl/certs`)
- `tls_key_path`: Private key storage path (default: `/etc/ssl/private`)
- `tls_cert_name`: Certificate filename prefix (default: `server`)
- `tls_key_size`: Private key size in bits (default: `2048`)
- `tls_cert_days`: Certificate validity period in days (default: `365`)

### Certificate Subject
- `tls_country`: Country code (default: `AU`)
- `tls_state`: State/province (default: `VIC`)
- `tls_city`: City/locality (default: `Melbourne`)
- `tls_organization`: Organization name (default: `Kubernetes Cluster`)
- `tls_organizational_unit`: Organizational unit (default: `Kubernetes`)
- `tls_common_name`: Common name (default: `{{ ansible_fqdn }}`)

### Subject Alternative Names
- `tls_san_dns`: DNS names list
- `tls_san_ip`: IP addresses list

### File Permissions
- `tls_cert_mode`: Certificate file mode (default: `0644`)
- `tls_key_mode`: Private key file mode (default: `0600`)
- `tls_cert_owner`: File owner (default: `root`)
- `tls_cert_group`: File group (default: `root`)

## Example Playbook

```yaml
- hosts: kubernetes
  become: yes
  roles:
    - role: tls
      vars:
        tls_cert_name: "kubernetes-api"
        tls_common_name: "kubernetes.example.com"
        tls_san_dns:
          - "kubernetes.example.com"
          - "k8s.example.com"
        tls_san_ip:
          - "10.0.0.1"
          - "192.168.1.100"
```

## Tags

- `tls`: All TLS-related tasks
- `validation`: Variable validation tasks
- `dependencies`: Dependency installation tasks

## Generated Files

- `{{ tls_cert_path }}/{{ tls_cert_name }}.crt`: Self-signed certificate
- `{{ tls_key_path }}/{{ tls_cert_name }}.key`: Private key
- `{{ tls_venv_path }}`: Python virtual environment for cryptography

## Security Considerations

- Private keys are stored with restrictive permissions (0600)
- Virtual environment is created in a secure location
- Certificate validity period should be appropriate for your use case
- Regular certificate rotation is recommended