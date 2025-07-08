# output "instance_names" {
#   description = "Names of created compute instances"
#   value       = [for instance in google_compute_instance.instances : instance.name]
# }

# output "instance_internal_ips" {
#   description = "Internal IP addresses of created instances"
#   value       = { for k, instance in google_compute_instance.instances : k => instance.network_interface[0].network_ip }
# }

# output "instance_zones" {
#   description = "Zones of created instances"
#   value       = { for k, instance in google_compute_instance.instances : k => instance.zone }
# }

# output "subnet_id" {
#   description = "ID of the created subnet"
#   value       = google_compute_subnetwork.private_subnet.id
# }

# output "subnet_name" {
#   description = "Name of the created subnet"
#   value       = google_compute_subnetwork.private_subnet.name
# }

output "nat_router_name" {
  description = "Name of the NAT router"
  value       = google_compute_router.nat_router.name
}

output "nat_gateway_name" {
  description = "Name of the NAT gateway"
  value       = google_compute_router_nat.nat_gateway.name
}

# output "firewall_rule_name" {
#   description = "Name of the firewall rule"
#   value       = google_compute_firewall.allow_ssh_http_https.name
# }