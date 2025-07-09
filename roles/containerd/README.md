# Containerd Role

This role installs and configures containerd container runtime for Kubernetes clusters.

## Features

- **Modular Design**: Separated into logical task files for better maintainability
- **Comprehensive Tagging**: All tasks properly tagged for selective execution
- **Idempotent Operations**: Safe to run multiple times
- **Validation Checks**: Built-in health checks and verification
- **Error Handling**: Retry logic and proper error handling
- **Backup Support**: Configuration files are backed up before changes

## Task Structure

- `main.yml` - Main orchestration file
- `directories.yml` - Creates required directories
- `dependencies.yml` - Installs runc and CNI plugins
- `install.yml` - Installs containerd binary and systemd service
- `service.yml` - Manages containerd service
- `validate.yml` - Validates installation and functionality

## Available Tags

### Primary Tags
- `containerd` - All containerd-related tasks
- `install` - Installation tasks
- `service` - Service management
- `validate` - Validation and testing

### Specific Tags
- `directories` - Directory creation
- `dependencies` - runc and CNI plugins
- `binary` - containerd binary installation
- `config` - Configuration tasks
- `systemd` - systemd service management
- `setup` - Setup and preparation tasks
- `verify` - Verification tasks
- `test` - Testing tasks

## Usage Examples

```bash
# Install everything
ansible-playbook playbook.yml --tags containerd

# Install only dependencies
ansible-playbook playbook.yml --tags dependencies

# Install and start service (skip validation)
ansible-playbook playbook.yml --tags "install,service"

# Run only validation
ansible-playbook playbook.yml --tags validate

# Skip validation during install
ansible-playbook playbook.yml --tags containerd --skip-tags validate
```

## Variables

See `defaults/main.yml` for all configurable variables including:
- Component versions (containerd, runc, CNI plugins)
- Download URLs
- Installation paths
- Configuration files

## Dependencies

- Internet access for downloading binaries
- systemd for service management
- Root privileges for installation

## Validation

The role includes comprehensive validation that checks:
- Binary installations and versions
- Service status and socket availability
- Configuration validity
- CNI plugin availability