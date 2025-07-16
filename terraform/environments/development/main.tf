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

terraform {
  required_version = ">= 1.12"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.43.0"
    }
  }
}

provider "google" {
  project     = var.gcp_project
  region      = var.region
  credentials = file(var.gcp_service_account_file)
}

module "gcp_infrastructure" {
  source = "../../modules/gcp-infrastructure"

  # GCP Configuration
  gcp_project = var.gcp_project
  region      = var.region

  # Network Configuration
  vpc_name    = var.vpc_name
  vpc_network = var.vpc_network
  zone_cidrs  = coalesce(var.zone_cidrs, local.dev_zone_cidrs)

  # Instance Configuration
  source_image  = var.source_image
  environment   = local.environment
  instance_tags = var.instance_tags

  # Security Configuration
  firewall_ports         = coalesce(var.firewall_ports, local.dev_firewall_ports)
  firewall_source_ranges = var.firewall_source_ranges

  # Node Groups Configuration
  node_groups = coalesce(var.node_groups, local.dev_node_groups)

  # Load Balancer Configuration
  lb_fixed_ip      = var.lb_fixed_ip
  join_controllers = var.join_controllers
}
