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

output "instance_names" {
  description = "Names of created compute instances"
  value       = [for instance in google_compute_instance.instances : instance.name]
}

output "instance_internal_ips" {
  description = "Internal IP addresses of created instances"
  value       = { for k, instance in google_compute_instance.instances : k => instance.network_interface[0].network_ip }
}

output "instance_zones" {
  description = "Zones of created instances"
  value       = { for k, instance in google_compute_instance.instances : k => instance.zone }
}

output "nat_router_name" {
  description = "Name of the NAT router"
  value       = google_compute_router.nat_router.name
}

output "nat_gateway_name" {
  description = "Name of the NAT gateway"
  value       = google_compute_router_nat.nat_gateway.name
}

output "firewall_rule_name" {
  description = "Name of the firewall rule"
  value       = google_compute_firewall.allow_external.name
}

output "lb_address" {
  description = "Load balancer static IP address (only created when multiple zones are configured)"
  value       = length(local.zone_keys) > 1 ? google_compute_address.lb_address[0].address : null
}

output "health_check_6443" {
  description = "Health check for port 8080 (only created when multiple zones are configured)"
  value = length(local.zone_keys) > 1 ? {
    id   = google_compute_region_health_check.tcp_6443[0].id
    name = google_compute_region_health_check.tcp_6443[0].name
  } : null
}

output "instance_groups" {
  description = "Instance groups by node group and zone (only created when multiple zones are configured)"
  value = length(local.zone_keys) > 1 ? {
    for group_key, group in google_compute_instance_group.node_groups : group_key => {
      id         = group.id
      name       = group.name
      zone       = group.zone
      size       = group.size
      node_group = local.instances_by_node_group_zone[group_key].group_name
    }
  } : null
}

output "instance_groups_by_node_group" {
  description = "Map of node group to instance group details (only created when multiple zones are configured)"
  value = length(local.zone_keys) > 1 ? {
    for group_key in keys(google_compute_instance_group.node_groups) : group_key => {
      group_name = google_compute_instance_group.node_groups[group_key].name
      group_id   = google_compute_instance_group.node_groups[group_key].id
      zone       = google_compute_instance_group.node_groups[group_key].zone
      instances  = google_compute_instance_group.node_groups[group_key].instances
      node_group = local.instances_by_node_group_zone[group_key].group_name
      zone_key   = local.instances_by_node_group_zone[group_key].zone_key
    }
  } : null
}

output "controller_load_balancer" {
  description = "Controller TCP load balancer details (only created when multiple zones are configured)"
  value = length(local.zone_keys) > 1 ? {
    backend_service_id = google_compute_region_backend_service.controller_backend[0].id
    forwarding_rule_id = google_compute_forwarding_rule.controller_lb[0].id
    ip_address         = google_compute_address.lb_address[0].address
    port_range         = "6443"
  } : null
}

output "ansible_inventory_data" {
  description = "Structured data for Ansible inventory generation"
  value = {
    hosts = {
      for k, instance in google_compute_instance.instances : k => {
        ansible_host = instance.network_interface[0].network_ip
        zone         = instance.zone
        labels       = instance.labels
        machine_type = instance.machine_type
        disk_size_gb = instance.boot_disk[0].initialize_params[0].size
        disk_type    = instance.boot_disk[0].initialize_params[0].type
        group_name   = lookup(local.instances_map[k], "group_name", "unknown")
      }
    }
    groups = {
      for group_name, group in var.node_groups : group_name => {
        hosts = [
          for k, instance in google_compute_instance.instances : k
          if lookup(local.instances_map[k], "group_name", "") == group_name
        ]
        vars = merge(
          {
            group_labels   = group.labels
            machine_type   = group.machine_type
            disk_size_gb   = group.disk_size_gb
            disk_type      = group.disk_type
            can_ip_forward = group.can_ip_forward
          },
          group_name == "controller" && length(local.zone_keys) > 1 ? {
            lb_address = google_compute_address.lb_address[0].address
          } : {}
        )
      }
    }
    env    = var.environment
    region = var.region
  }
}
