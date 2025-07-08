terraform {
  required_version = ">= 1.12"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.42.0"
    }
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

resource "google_compute_firewall" "allow_ssh_http_https" {
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

locals {
  # Generate instances from node_groups
  node_group_instances = flatten([
    for group_name, group in var.node_groups : [
      for i in range(group.count) : {
        name         = "${coalesce(group.base_name, group_name)}-${format("%02d", i + 1)}"
        group_name   = group_name
        machine_type = group.machine_type
        disk_size_gb = group.disk_size_gb
        disk_type    = group.disk_type
        zone_suffix  = ["a", "b", "c"][i % 3]
        labels       = group.labels
        # Calculate IP address based on zone and instance index
        ip_address     = cidrhost(var.zone_cidrs[["a", "b", "c"][i % 3]], group.base_address + floor(i / 3))
        can_ip_forward = group.can_ip_forward
      }
    ]
  ])

  instances_map = { for instance in local.node_group_instances : instance.name => instance }
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
