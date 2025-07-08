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
      version = "~> 6.42.0"
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

  gcp_project            = var.gcp_project
  gcp_project_id         = var.gcp_project_id
  region                 = var.region
  vpc_name               = var.vpc_name
  vpc_network            = var.vpc_network
  machine_type           = var.machine_type
  source_image           = var.source_image
  disk_size_gb           = var.disk_size_gb
  environment            = var.environment
  instance_tags          = var.instance_tags
  firewall_ports         = var.firewall_ports
  firewall_source_ranges = var.firewall_source_ranges
  zone_cidrs             = var.zone_cidrs
  node_groups            = var.node_groups
  instances              = var.instances
}
