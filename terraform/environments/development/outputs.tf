# output "instance_names" {
#   description = "Names of created compute instances"
#   value       = module.gcp_infrastructure.instance_names
# }

# output "instance_internal_ips" {
#   description = "Internal IP addresses of created instances"
#   value       = module.gcp_infrastructure.instance_internal_ips
# }

# output "instance_zones" {
#   description = "Zones of created instances"
#   value       = module.gcp_infrastructure.instance_zones
# }

# output "subnet_id" {
#   description = "ID of the created subnet"
#   value       = module.gcp_infrastructure.subnet_id
# }

output "nat_router_name" {
  description = "Name of the NAT router"
  value       = module.gcp_infrastructure.nat_router_name
}

output "nat_gateway_name" {
  description = "Name of the NAT gateway"
  value       = module.gcp_infrastructure.nat_gateway_name
}