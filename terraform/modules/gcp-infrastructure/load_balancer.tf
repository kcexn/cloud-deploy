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

# Static IP address for load balancer (multi-zone only)
resource "google_compute_address" "lb_address" {
  count        = local.is_multi_zone ? 1 : 0
  name         = "${local.resource_prefix}-lb-address"
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = "${var.vpc_network}/subnetworks/default"
  address      = var.lb_fixed_ip
}

# Health check for Kubernetes API server (multi-zone only)
resource "google_compute_region_health_check" "tcp_6443" {
  count              = local.is_multi_zone ? 1 : 0
  name               = "${local.resource_prefix}-tcp-6443"
  description        = "TCP health check for Kubernetes API server port 6443"
  timeout_sec        = 5
  check_interval_sec = 10
  region             = var.region

  tcp_health_check {
    port = 6443
  }
}

# Backend service for controller load balancer (multi-zone only)
resource "google_compute_region_backend_service" "controller_backend" {
  count                 = local.is_multi_zone ? 1 : 0
  name                  = "${local.resource_prefix}-controller-backend"
  description           = "Regional backend service for controller nodes"
  protocol              = "TCP"
  health_checks         = [google_compute_region_health_check.tcp_6443[0].id]
  load_balancing_scheme = "INTERNAL"
  session_affinity      = "NONE"
  region                = var.region

  dynamic "backend" {
    for_each = {
      for idx, group_key in sort(keys({
        for group_key, group_data in local.instances_by_node_group_zone :
        group_key => group_data if group_data.group_name == "controller"
      })) : idx => group_key if idx == 0 || var.join_controllers
    }
    content {
      balancing_mode = "CONNECTION"
      group          = google_compute_instance_group.node_groups[backend.value].id
      failover       = false
    }
  }
}

# Forwarding rule for controller load balancer (multi-zone only)
resource "google_compute_forwarding_rule" "controller_lb" {
  count                 = local.is_multi_zone ? 1 : 0
  name                  = "${local.resource_prefix}-controller-lb"
  description           = "Forwarding rule for controller TCP passthrough load balancer"
  region                = var.region
  all_ports             = true
  ip_address            = google_compute_address.lb_address[0].id
  backend_service       = google_compute_region_backend_service.controller_backend[0].id
  load_balancing_scheme = "INTERNAL"
  subnetwork            = "${var.vpc_network}/subnetworks/default"
}

# Global TCP Proxy Load Balancer for HTTP traffic (port 80 to NodePort)
# Only deployed when nodeport_service_port is defined

# Global static IP address for TCP proxy load balancer
resource "google_compute_global_address" "tcp_proxy_lb_ip" {
  count        = var.nodeport_service_port != null ? 1 : 0
  name         = "${local.resource_prefix}-tcp-proxy-lb-ip"
  description  = "Static IP for global TCP proxy load balancer"
  address_type = "EXTERNAL"
}

# Global health check for NodePort service
resource "google_compute_health_check" "nodeport_health_check" {
  count               = var.nodeport_service_port != null ? 1 : 0
  name                = "${local.resource_prefix}-nodeport-health-check"
  description         = "Health check for NodePort service on port ${var.nodeport_service_port}"
  timeout_sec         = 5
  check_interval_sec  = 10
  healthy_threshold   = 2
  unhealthy_threshold = 3

  tcp_health_check {
    port = var.nodeport_service_port
  }
}

# Global backend service for TCP proxy load balancer (unmanaged)
resource "google_compute_backend_service" "tcp_proxy_backend" {
  count                 = var.nodeport_service_port != null ? 1 : 0
  name                  = "${local.resource_prefix}-tcp-proxy-backend"
  description           = "Unmanaged backend service for global TCP proxy load balancer"
  protocol              = "TCP"
  port_name             = "nodeport"
  health_checks         = [google_compute_health_check.nodeport_health_check[0].id]
  load_balancing_scheme = "EXTERNAL"
  session_affinity      = "NONE"
  timeout_sec           = 30

  # Add all instance groups as backends
  dynamic "backend" {
    for_each = google_compute_instance_group.node_groups
    content {
      group                     = backend.value.id
      balancing_mode            = "CONNECTION"
      max_connections_per_instance = 1000
    }
  }
}

# Global target TCP proxy
resource "google_compute_target_tcp_proxy" "tcp_proxy" {
  count           = var.nodeport_service_port != null ? 1 : 0
  name            = "${local.resource_prefix}-tcp-proxy"
  description     = "Global TCP proxy for HTTP traffic forwarding to NodePort"
  backend_service = google_compute_backend_service.tcp_proxy_backend[0].id
}

# Global forwarding rule for HTTP traffic (port 80)
resource "google_compute_global_forwarding_rule" "tcp_proxy_forwarding_rule" {
  count                 = var.nodeport_service_port != null ? 1 : 0
  name                  = "${local.resource_prefix}-tcp-proxy-forwarding-rule"
  description           = "Forwards HTTP traffic on port 80 to NodePort ${var.nodeport_service_port}"
  ip_address            = google_compute_global_address.tcp_proxy_lb_ip[0].id
  ip_protocol           = "TCP"
  port_range            = "80"
  target                = google_compute_target_tcp_proxy.tcp_proxy[0].id
  load_balancing_scheme = "EXTERNAL"
}
