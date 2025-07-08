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
  value       = module.gcp_infrastructure.instance_names
}

output "instance_internal_ips" {
  description = "Internal IP addresses of created instances"
  value       = module.gcp_infrastructure.instance_internal_ips
}

output "instance_zones" {
  description = "Zones of created instances"
  value       = module.gcp_infrastructure.instance_zones
}

output "nat_router_name" {
  description = "Name of the NAT router"
  value       = module.gcp_infrastructure.nat_router_name
}

output "nat_gateway_name" {
  description = "Name of the NAT gateway"
  value       = module.gcp_infrastructure.nat_gateway_name
}

output "firewall_rule_name" {
  description = "Name of the firewall rule"
  value       = module.gcp_infrastructure.firewall_rule_name
}

output "ansible_inventory_data" {
  description = "Structured data for Ansible inventory generation"
  value       = module.gcp_infrastructure.ansible_inventory_data
}
