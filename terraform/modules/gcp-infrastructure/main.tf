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

locals {
  # Extract zone keys for readability
  zone_keys  = keys(var.zone_cidrs)
  zone_count = length(local.zone_keys)

  # Generate instances from node_groups
  node_group_instances = flatten([
    for group_name, group in var.node_groups : (
      # Handle groups with subgroups (like worker)
      lookup(group, "subgroups", null) != null ? 
        flatten([
          for subgroup_name, subgroup in group.subgroups : [
            for i in range(subgroup.count) : {
              name         = "${coalesce(subgroup.base_name, "${group_name}-${subgroup_name}")}-${format("%02d", i + 1)}"
              group_name   = group_name
              subgroup_name = subgroup_name
              machine_type = subgroup.machine_type == null ? group.machine_type : subgroup.machine_type
              disk_size_gb = subgroup.disk_size_gb == null ? group.disk_size_gb : subgroup.disk_size_gb
              disk_type    = subgroup.disk_type == null ? group.disk_type : subgroup.disk_type
              zone_suffix  = local.zone_keys[i % local.zone_count]
              labels       = merge(group.labels, subgroup.labels)
              # Calculate IP address based on zone and instance index
              can_ip_forward = subgroup.can_ip_forward == null ? group.can_ip_forward : subgroup.can_ip_forward
              ip_address     = cidrhost(
                var.zone_cidrs[local.zone_keys[i % local.zone_count]], 
                subgroup.base_address == null ? group.base_address + floor(i / local.zone_count) : subgroup.base_address + floor(i / local.zone_count)
              )
            }
          ]
        ]) : 
        # Handle groups without subgroups (like controller)
        [
          for i in range(group.count) : {
            name         = "${coalesce(group.base_name, group_name)}-${format("%02d", i + 1)}"
            group_name   = group_name
            subgroup_name = null
            machine_type = group.machine_type
            disk_size_gb = group.disk_size_gb
            disk_type    = group.disk_type
            zone_suffix  = local.zone_keys[i % local.zone_count]
            labels       = group.labels
            # Calculate IP address based on zone and instance index
            ip_address     = cidrhost(var.zone_cidrs[local.zone_keys[i % local.zone_count]], group.base_address + floor(i / local.zone_count))
            can_ip_forward = group.can_ip_forward
          }
        ]
    )
  ])


  instances_map = { for instance in local.node_group_instances : instance.name => instance }
}

resource "google_compute_address" "lb_address" {
  count        = length(local.zone_keys) > 1 ? 1 : 0
  name         = "ansible-lb-address"
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = "${var.vpc_network}/subnetworks/default"
  address      = var.lb_fixed_ip
}

resource "google_compute_region_health_check" "tcp_6443" {
  count              = length(local.zone_keys) > 1 ? 1 : 0
  name               = "${var.vpc_name}-${var.environment}-tcp-6443"
  description        = "TCP health check for port 6443"
  timeout_sec        = 5
  check_interval_sec = 10
  region             = var.region

  tcp_health_check {
    port = 6443
  }
}

resource "google_compute_router" "nat_router" {
  name    = "${var.vpc_name}-router"
  region  = var.region
  network = var.vpc_network
}

resource "google_compute_router_nat" "nat_gateway" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

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

resource "google_compute_instance" "instances" {
  for_each = local.instances_map

  name           = each.key
  machine_type   = lookup(each.value, "machine_type", var.machine_type)
  zone           = "${var.region}-${each.value.zone_suffix}"
  can_ip_forward = lookup(each.value, "can_ip_forward", false)

  boot_disk {
    initialize_params {
      image = var.source_image
      size  = lookup(each.value, "disk_size_gb", var.disk_size_gb)
      type  = lookup(each.value, "disk_type", var.disk_type)
    }
  }

  network_interface {
    network    = var.vpc_network
    network_ip = lookup(each.value, "ip_address", lookup(each.value, "ansible_host", null))
  }

  tags = var.instance_tags

  labels = merge(
    {
      environment           = var.environment
      goog-ops-agent-policy = "v2-x86-template-1-4-0"
      goog-ec-src           = "vm_add-rest"
    },
    lookup(each.value, "labels", {})
  )

  metadata = {
    enable-oslogin  = "TRUE"
    enable-osconfig = "TRUE"
    startup-script  = templatefile("${path.module}/startup-script.sh", {})
  }

  service_account {
    email = "${var.gcp_project_id}-compute@developer.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }
}

locals {
  # Group instances by node group and zone (only when multiple zones are configured)
  instances_by_node_group_zone = length(local.zone_keys) > 1 ? {
    for combo in flatten([
      for group_name in keys(var.node_groups) : [
        for zone_key in local.zone_keys : {
          key        = "${group_name}-${zone_key}"
          group_name = group_name
          zone_key   = zone_key
          zone       = "${var.region}-${zone_key}"
          instances = [
            for instance_name, instance_data in local.instances_map :
            google_compute_instance.instances[instance_name].id
            if instance_data.group_name == group_name && instance_data.zone_suffix == zone_key
          ]
        }
      ]
    ]) : combo.key => combo if length(combo.instances) > 0
  } : {}
}

resource "google_compute_instance_group" "node_groups" {
  for_each = local.instances_by_node_group_zone

  name        = "${var.environment}-${each.key}"
  description = "Instance group for ${each.value.group_name} in zone ${each.value.zone}"
  zone        = each.value.zone

  instances = each.value.instances

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "http-alt"
    port = "8080"
  }

  named_port {
    name = "https"
    port = "443"
  }

  dynamic "named_port" {
    for_each = each.value.group_name == "controller" ? [1] : []
    content {
      name = "k8s-api"
      port = "6443"
    }
  }
}

# TCP Passthrough Load Balancer for Controllers (only when multiple zones)
resource "google_compute_region_backend_service" "controller_backend" {
  count                 = length(local.zone_keys) > 1 ? 1 : 0
  name                  = "${var.vpc_name}-${var.environment}-controller-backend"
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

resource "google_compute_forwarding_rule" "controller_lb" {
  count                 = length(local.zone_keys) > 1 ? 1 : 0
  name                  = "${var.vpc_name}-${var.environment}-controller-lb"
  description           = "Forwarding rule for controller TCP passthrough load balancer"
  region                = var.region
  all_ports             = true
  ip_address            = google_compute_address.lb_address[0].id
  backend_service       = google_compute_region_backend_service.controller_backend[0].id
  load_balancing_scheme = "INTERNAL"
  subnetwork            = "${var.vpc_network}/subnetworks/default"
}
