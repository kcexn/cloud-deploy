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
}

variable "gcp_project_id" {
  description = "GCP project ID for service account"
  type        = string
}

variable "gcp_service_account_file" {
  description = "Path to GCP service account JSON file"
  type        = string
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
  description = "CIDR ranges for each zone"
  type        = map(string)
  default = {
    "a" = "10.0.1.0/24"
    "b" = "10.0.2.0/24"
    "c" = "10.0.3.0/24"
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
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "environment" {
  description = "Environment name"
  type        = string
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
  description = "Source IP ranges for firewall rules"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "node_groups" {
  description = "Kubernetes node groups configuration"
  type = map(object({
    count          = number
    machine_type   = string
    disk_size_gb   = number
    disk_type      = optional(string, "pd-standard")
    labels         = map(string)
    base_name      = optional(string)
    base_address   = number
    can_ip_forward = optional(bool, false)
  }))
}

variable "instances" {
  description = "Map of instance configurations (deprecated, use node_groups)"
  type = map(object({
    zone_suffix    = string
    ansible_host   = string
    labels         = optional(map(string), {})
    machine_type   = optional(string)
    disk_size_gb   = optional(number)
    disk_type      = optional(string)
    can_ip_forward = optional(bool, false)
  }))
  default = {}
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
