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

variable "gcp_project" {
  description = "GCP project ID"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.gcp_project))
    error_message = "GCP project ID must be 6-30 characters, start with a lowercase letter, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-east1"
}

variable "vpc_name" {
  description = "Name prefix for VPC resources"
  type        = string
  default     = "ansible"
}

variable "vpc_network" {
  description = "VPC network self-link"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "zone_cidrs" {
  description = "CIDR ranges for each zone (keys should be zone suffixes like 'a', 'b', 'c')"
  type        = map(string)
  default = {
    "a" = "10.0.1.0/24"
    "b" = "10.0.2.0/24"
    "c" = "10.0.3.0/24"
  }

  validation {
    condition = alltrue([
      for zone, cidr in var.zone_cidrs : can(cidrhost(cidr, 0))
    ])
    error_message = "All zone CIDRs must be valid CIDR notation."
  }

  validation {
    condition     = length(var.zone_cidrs) > 0
    error_message = "At least one zone CIDR must be specified."
  }
}

variable "machine_type" {
  description = "Machine type for compute instances"
  type        = string
  default     = "e2-micro"
}

variable "source_image" {
  description = "Source image for compute instances"
  type        = string
  default     = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2004-lts"
}

variable "disk_size_gb" {
  description = "Disk size in GB (minimum 10 GB)"
  type        = number
  default     = 20

  validation {
    condition     = var.disk_size_gb >= 10
    error_message = "Disk size must be at least 10 GB."
  }
}

variable "disk_type" {
  description = "Disk type for compute instances (pd-standard, pd-ssd, pd-balanced)"
  type        = string
  default     = "pd-standard"

  validation {
    condition     = contains(["pd-standard", "pd-ssd", "pd-balanced"], var.disk_type)
    error_message = "Disk type must be one of: pd-standard, pd-ssd, pd-balanced."
  }
}

variable "environment" {
  description = "Environment name (e.g., development, staging, production)"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*[a-z0-9]$", var.environment))
    error_message = "Environment name must start with a lowercase letter and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "instance_tags" {
  description = "Tags for compute instances"
  type        = list(string)
  default     = ["ansible-vm"]
}

variable "firewall_ports" {
  description = "Firewall ports to allow"
  type        = list(string)
  default     = ["22", "80", "443"]
}

variable "firewall_source_ranges" {
  description = "Source IP ranges for firewall rules. Use specific ranges for security."
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for range in var.firewall_source_ranges : can(cidrhost(range, 0))
    ])
    error_message = "All firewall source ranges must be valid CIDR notation."
  }
}

variable "node_groups" {
  description = "Kubernetes node groups configuration with support for subgroups"
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

  validation {
    condition = alltrue([
      for group_name, group in var.node_groups : (
        group.count != null || group.subgroups != null
      )
    ])
    error_message = "Each node group must have either a 'count' or 'subgroups' defined."
  }

  validation {
    condition = alltrue([
      for group_name, group in var.node_groups : (
        group.subgroups != null ? alltrue([
          for subgroup_name, subgroup in group.subgroups : subgroup.count > 0
        ]) : true
      )
    ])
    error_message = "All subgroups must have a count greater than 0."
  }
}


variable "join_controllers" {
  description = "Whether to add secondary/tertiary controllers to the load balancer"
  type        = bool
  default     = false
}

variable "lb_fixed_ip" {
  description = "Fixed IP address for load balancer (optional)"
  type        = string
  default     = null
}

variable "nodeport_service_port" {
  description = "NodePort service port that the load balancer should forward traffic to. If null, TCP proxy load balancer will not be deployed."
  type        = number
  default     = null
  
  validation {
    condition     = var.nodeport_service_port == null || (var.nodeport_service_port >= 30000 && var.nodeport_service_port <= 32767)
    error_message = "NodePort service port must be between 30000 and 32767."
  }
}
