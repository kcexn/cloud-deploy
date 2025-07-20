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

# NAT Router for outbound internet access
resource "google_compute_router" "nat_router" {
  name    = "${var.vpc_name}-router"
  region  = var.region
  network = var.vpc_network
}

# NAT Gateway for outbound internet access
resource "google_compute_router_nat" "nat_gateway" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Firewall rule for external access
resource "google_compute_firewall" "allow_external" {
  name    = "${var.vpc_name}-allow"
  network = var.vpc_network

  allow {
    protocol = "tcp"
    ports    = var.firewall_ports
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = var.firewall_source_ranges
  target_tags   = var.instance_tags
}

# Firewall rule to allow load balancer health checks
resource "google_compute_firewall" "allow_lb_health_checks" {
  count   = var.nodeport_service_port != null ? 1 : 0
  name    = "${var.vpc_name}-allow-lb-health-checks"
  network = var.vpc_network
  
  description = "Allow Google Cloud Load Balancer health checks"

  allow {
    protocol = "tcp"
    ports    = [var.nodeport_service_port]
  }

  # Google Cloud Load Balancer health check source ranges
  source_ranges = [
    "35.191.0.0/16",    # Google Cloud Load Balancer health checks
    "130.211.0.0/22"    # Google Cloud Load Balancer health checks
  ]
  
  target_tags = var.instance_tags
}

# Firewall rule to allow load balancer traffic to NodePort
resource "google_compute_firewall" "allow_lb_to_nodeport" {
  count   = var.nodeport_service_port != null ? 1 : 0
  name    = "${var.vpc_name}-allow-lb-to-nodeport"
  network = var.vpc_network
  
  description = "Allow load balancer traffic to NodePort service"

  allow {
    protocol = "tcp"
    ports    = [var.nodeport_service_port]
  }

  # Google Cloud Load Balancer proxy source ranges
  source_ranges = [
    "35.191.0.0/16",    # Google Cloud Load Balancer
    "130.211.0.0/22"    # Google Cloud Load Balancer
  ]
  
  target_tags = var.instance_tags
}
