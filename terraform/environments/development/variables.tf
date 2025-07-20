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

# ============================================================================
# GCP Provider Configuration
# ============================================================================

variable "gcp_project" {
  description = "GCP project ID for the development environment"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.gcp_project))
    error_message = "GCP project ID must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "gcp_service_account_file" {
  description = "Path to GCP service account JSON file"
  type        = string

  validation {
    condition     = can(regex(".*\\.json$", var.gcp_service_account_file))
    error_message = "Service account file must be a JSON file."
  }
}

variable "region" {
  description = "GCP region for development deployment"
  type        = string
  default     = "australia-southeast1"

  validation {
    condition     = can(regex("^[a-z]+-[a-z0-9]+$", var.region))
    error_message = "Region must be a valid GCP region format (e.g., us-central1, australia-southeast1)."
  }
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "vpc_name" {
  description = "Name prefix for VPC resources"
  type        = string
  default     = "ansible"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.vpc_name))
    error_message = "VPC name must start with a lowercase letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "vpc_network" {
  description = "VPC network self-link for the development environment"
  type        = string

  validation {
    condition     = can(regex("^https://www\\.googleapis\\.com/compute/v1/projects/.+/global/networks/.+$", var.vpc_network))
    error_message = "VPC network must be a valid GCP network self-link."
  }
}

variable "zone_cidrs" {
  description = "CIDR ranges for each zone (development uses single zone by default)"
  type        = map(string)
  default     = null # Use locals.dev_zone_cidrs if not specified

  validation {
    condition = var.zone_cidrs == null || alltrue([
      for zone, cidr in var.zone_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All zone CIDRs must be valid CIDR notation."
  }
}

# ============================================================================
# Instance Configuration
# ============================================================================

variable "source_image" {
  description = "Source image for compute instances (development uses Debian 12)"
  type        = string
  default     = "projects/debian-cloud/global/images/debian-12-bookworm-v20250709"

  validation {
    condition     = can(regex("^projects/.+/global/images/.+$", var.source_image))
    error_message = "Source image must be a valid GCP image reference."
  }
}

variable "instance_tags" {
  description = "Tags for compute instances"
  type        = list(string)
  default     = ["ansible-vm", "development"]

  validation {
    condition     = length(var.instance_tags) > 0
    error_message = "At least one instance tag must be specified."
  }
}

# ============================================================================
# Security Configuration
# ============================================================================

variable "firewall_ports" {
  description = "Firewall ports to allow (development includes additional ports)"
  type        = list(string)
  default     = null # Use locals.dev_firewall_ports if not specified
}

variable "firewall_source_ranges" {
  description = "Source IP ranges for firewall rules (restrict for production)"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for range in var.firewall_source_ranges : can(cidrhost(range, 0))
    ])
    error_message = "All firewall source ranges must be valid CIDR notation."
  }
}

# ============================================================================
# Node Groups Configuration
# ============================================================================

variable "node_groups" {
  description = "Kubernetes node groups configuration (uses development defaults if not specified)"
  type = map(object({
    count          = optional(number)
    base_name      = optional(string)
    machine_type   = optional(string)
    disk_size_gb   = optional(number)
    disk_type      = optional(string)
    labels         = optional(map(string), {})
    base_address   = optional(number)
    can_ip_forward = optional(bool)
    subgroups = optional(map(object({
      count          = number
      base_name      = string
      machine_type   = optional(string)
      disk_size_gb   = optional(number)
      disk_type      = optional(string)
      labels         = optional(map(string), {})
      base_address   = optional(number)
      can_ip_forward = optional(bool)
    })))
  }))
  default = null # Use locals.dev_node_groups if not specified
}

# ============================================================================
# Load Balancer Configuration
# ============================================================================

variable "join_controllers" {
  description = "Whether to add secondary/tertiary controllers to the load balancer (development: false)"
  type        = bool
  default     = false
}

variable "lb_fixed_ip" {
  description = "Fixed IP address for load balancer (optional, development uses 10.152.0.6)"
  type        = string
  default     = "10.152.0.6"

  validation {
    condition     = var.lb_fixed_ip == null || can(regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$", var.lb_fixed_ip))
    error_message = "Load balancer fixed IP must be a valid IPv4 address."
  }
}

variable "nodeport_service_port" {
  description = "NodePort service port that the TCP proxy load balancer should forward traffic to"
  type        = number
  default     = 30080
  
  validation {
    condition     = var.nodeport_service_port >= 30000 && var.nodeport_service_port <= 32767
    error_message = "NodePort service port must be between 30000 and 32767."
  }
}

