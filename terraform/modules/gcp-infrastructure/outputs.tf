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
  value       = google_compute_firewall.allow_ssh_http_https.name
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
        vars = {
          group_labels = group.labels
          machine_type = group.machine_type
          disk_size_gb = group.disk_size_gb
          disk_type    = group.disk_type
        }
      }
    }
    env    = var.environment
    region = var.region
  }
}
