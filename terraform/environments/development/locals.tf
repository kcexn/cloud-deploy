# Cluster deployment automation system
# Copyright 2025 Kevin Exton
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

locals {
  # Environment-specific configuration
  environment = "development"

  # Multi-zone deployment flag
  is_multi_zone = length(keys(coalesce(var.zone_cidrs, local.dev_zone_cidrs))) > 1

  # Common resource naming
  name_prefix = "${var.vpc_name}-${local.environment}"

  # Default node group configuration for development
  default_node_config = {
    machine_type   = "e2-medium"
    disk_size_gb   = 40
    disk_type      = "pd-balanced"
    can_ip_forward = true
    labels = {
      environment = local.environment
      role        = "k8s"
    }
  }

  # Development-specific firewall configuration
  dev_firewall_ports = [
    "22",   # SSH
    "80",   # HTTP
    "8080", # HTTP Alt (development)
    "443",  # HTTPS
    "6443", # Kubernetes API
  ]

  # Development zone configuration (single zone for cost optimization)
  dev_zone_cidrs = {
    "a" = "10.152.1.0/24"
    # Additional zones can be enabled for HA testing:
    # "b" = "10.152.2.0/24"
    # "c" = "10.152.3.0/24"
  }

  # Development node groups with reasonable defaults
  dev_node_groups = {
    controller = merge(local.default_node_config, {
      count        = 1
      base_name    = "${local.environment}-controller"
      base_address = 10
      labels = merge(local.default_node_config.labels, {
        tier = "controller"
      })
    })

    worker = merge(local.default_node_config, {
      base_address = 20
      disk_type    = "pd-standard" # Cost optimization for workers
      labels = merge(local.default_node_config.labels, {
        tier = "worker"
      })
      subgroups = {
        general = {
          count     = 1 # Single worker for development
          base_name = "${local.environment}-worker-general"
          labels = {
            subgroup = "general"
          }
        }
      }
    })
  }
}
