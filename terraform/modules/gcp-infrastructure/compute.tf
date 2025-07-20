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

# Get the default compute service account
data "google_compute_default_service_account" "default" {}

# Compute instances for Kubernetes nodes
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
    network_ip = lookup(each.value, "ip_address", null)
  }

  tags = var.instance_tags

  labels = merge(
    local.common_labels,
    lookup(each.value, "labels", {})
  )

  metadata = {
    enable-oslogin  = "TRUE"
    enable-osconfig = "TRUE"
    startup-script  = templatefile("${path.module}/startup-script.sh", {})
  }

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = local.compute_scopes
  }
}

# Instance groups for load balancer backends (multi-zone only)
resource "google_compute_instance_group" "node_groups" {
  for_each = local.instances_by_node_group_zone

  name        = "${local.resource_prefix}-${each.key}"
  description = "Instance group for ${each.value.group_name} in zone ${each.value.zone}"
  zone        = each.value.zone

  instances = [
    for instance_name, instance_data in local.instances_map :
    google_compute_instance.instances[instance_name].id
    if instance_data.group_name == each.value.group_name && instance_data.zone_suffix == each.value.zone_key
  ]

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
    for_each = var.nodeport_service_port != null ? [1] : []
    content {
      name = "nodeport"
      port = var.nodeport_service_port
    }
  }

  dynamic "named_port" {
    for_each = each.value.group_name == "controller" ? [1] : []
    content {
      name = "k8s-api"
      port = "6443"
    }
  }
}
