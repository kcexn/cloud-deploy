terraform {
  required_version = ">= 1.12"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.42.0"
    }
  }
}

# Create NAT router
resource "google_compute_router" "nat_router" {
  name    = "${var.vpc_name}-router"
  region  = var.region
  network = var.vpc_network
}

# Create NAT gateway
resource "google_compute_router_nat" "nat_gateway" {
  name                               = "${var.vpc_name}-nat"
  router                             = google_compute_router.nat_router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

# Create firewall rules
# resource "google_compute_firewall" "allow_ssh_http_https" {
#   name    = "${var.vpc_name}-allow"
#   network = var.vpc_network

#   allow {
#     protocol = "tcp"
#     ports    = var.firewall_ports
#   }

#   allow {
#     protocol = "icmp"
#   }

#   source_ranges = var.firewall_source_ranges
#   target_tags   = var.instance_tags
# }

# # Create compute instances
# resource "google_compute_instance" "instances" {
#   for_each = var.instances

#   name         = each.key
#   machine_type = var.machine_type
#   zone         = "${var.region}-${each.value.zone_suffix}"

#   boot_disk {
#     initialize_params {
#       image = var.source_image
#       size  = var.disk_size_gb
#     }
#   }

#   network_interface {
#     subnetwork = google_compute_subnetwork.private_subnet.id
#     network_ip = each.value.ansible_host
#   }

#   tags = var.instance_tags

#   labels = {
#     environment             = var.environment
#     goog-ops-agent-policy  = "v2-x86-template-1-4-0"
#     goog-ec-src           = "vm_add-rest"
#   }

#   metadata = {
#     enable-oslogin  = "TRUE"
#     enable-osconfig = "TRUE"
#     startup-script = templatefile("${path.module}/startup-script.sh", {})
#   }

#   service_account {
#     email = "${var.gcp_project_id}-compute@developer.gserviceaccount.com"
#     scopes = [
#       "https://www.googleapis.com/auth/devstorage.read_only",
#       "https://www.googleapis.com/auth/logging.write",
#       "https://www.googleapis.com/auth/monitoring.write",
#       "https://www.googleapis.com/auth/service.management.readonly",
#       "https://www.googleapis.com/auth/servicecontrol",
#       "https://www.googleapis.com/auth/trace.append"
#     ]
#   }
# }
