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

# Core infrastructure outputs (always available)
output "ansible_inventory_data" {
  description = "Structured data for Ansible inventory generation"
  value       = module.gcp_infrastructure.ansible_inventory_data
}

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

# Networking outputs
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

# Development environment summary
output "development_summary" {
  description = "Summary of development environment configuration"
  value = {
    environment    = local.environment
    is_multi_zone  = local.is_multi_zone
    zone_count     = length(keys(coalesce(var.zone_cidrs, local.dev_zone_cidrs)))
    instance_count = length(module.gcp_infrastructure.instance_names)
    node_groups    = keys(coalesce(var.node_groups, local.dev_node_groups))
    region         = var.region
    vpc_name       = var.vpc_name
  }
}

# Multi-zone specific outputs (only available when multiple zones are configured)
output "health_check_6443" {
  description = "Health check for port 6443 (only created when multiple zones are configured)"
  value       = local.is_multi_zone ? module.gcp_infrastructure.health_check_6443 : null
}

output "instance_groups" {
  description = "Instance groups by zone (only created when multiple zones are configured)"
  value       = local.is_multi_zone ? module.gcp_infrastructure.instance_groups : null
}

output "instance_groups_by_node_group" {
  description = "Map of zone to instance group details (only created when multiple zones are configured)"
  value       = local.is_multi_zone ? module.gcp_infrastructure.instance_groups_by_node_group : null
}

output "controller_load_balancer" {
  description = "Controller TCP load balancer details (only created when multiple zones are configured)"
  value       = local.is_multi_zone ? module.gcp_infrastructure.controller_load_balancer : null
}

output "lb_address" {
  description = "Load balancer static IP address (only created when multiple zones are configured)"
  value       = local.is_multi_zone ? module.gcp_infrastructure.lb_address : null
}
