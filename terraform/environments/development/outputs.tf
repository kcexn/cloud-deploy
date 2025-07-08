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
