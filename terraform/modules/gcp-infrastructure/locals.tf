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

locals {
  # Extract zone keys for readability
  zone_keys  = keys(var.zone_cidrs)
  zone_count = length(local.zone_keys)

  # Generate instances from node_groups
  node_group_instances = flatten([
    for group_name, group in var.node_groups : (
      # Handle groups with subgroups (like worker)
      lookup(group, "subgroups", null) != null ?
      flatten([
        for subgroup_name, subgroup in group.subgroups : [
          for i in range(subgroup.count) : {
            name           = "${coalesce(subgroup.base_name, "${group_name}-${subgroup_name}")}-${format("%02d", i + 1)}"
            group_name     = group_name
            subgroup_name  = subgroup_name
            machine_type   = subgroup.machine_type == null ? group.machine_type : subgroup.machine_type
            disk_size_gb   = subgroup.disk_size_gb == null ? group.disk_size_gb : subgroup.disk_size_gb
            disk_type      = subgroup.disk_type == null ? group.disk_type : subgroup.disk_type
            zone_suffix    = local.zone_keys[i % local.zone_count]
            labels         = merge(group.labels, subgroup.labels)
            can_ip_forward = subgroup.can_ip_forward == null ? group.can_ip_forward : subgroup.can_ip_forward
            ip_address = cidrhost(
              var.zone_cidrs[local.zone_keys[i % local.zone_count]],
              subgroup.base_address == null ? group.base_address + floor(i / local.zone_count) : subgroup.base_address + floor(i / local.zone_count)
            )
          }
        ]
      ]) :
      # Handle groups without subgroups (like controller)
      [
        for i in range(group.count) : {
          name           = "${coalesce(group.base_name, group_name)}-${format("%02d", i + 1)}"
          group_name     = group_name
          subgroup_name  = null
          machine_type   = group.machine_type
          disk_size_gb   = group.disk_size_gb
          disk_type      = group.disk_type
          zone_suffix    = local.zone_keys[i % local.zone_count]
          labels         = group.labels
          ip_address     = cidrhost(var.zone_cidrs[local.zone_keys[i % local.zone_count]], group.base_address + floor(i / local.zone_count))
          can_ip_forward = group.can_ip_forward
        }
      ]
    )
  ])

  instances_map = { for instance in local.node_group_instances : instance.name => instance }

  # Group instances by node group and zone (only when multiple zones are configured)
  instances_by_node_group_zone = {
    for combo in flatten([
      for group_name in keys(var.node_groups) : [
        for zone_key in local.zone_keys : {
          key        = "${group_name}-${zone_key}"
          group_name = group_name
          zone_key   = zone_key
          zone       = "${var.region}-${zone_key}"
          instances = [
            for instance_name, instance_data in local.instances_map :
            "${var.gcp_project}/zones/${var.region}-${zone_key}/instances/${instance_name}"
            if instance_data.group_name == group_name && instance_data.zone_suffix == zone_key
          ]
        }
      ]
    ]) : combo.key => combo if length(combo.instances) > 0
  }

  # Resource naming conventions
  resource_prefix = "${var.vpc_name}-${var.environment}"

  # Common labels for all resources
  common_labels = {
    environment           = var.environment
    vpc_name              = var.vpc_name
    terraform_managed     = "true"
    goog-ops-agent-policy = "v2-x86-template-1-4-0"
    goog-ec-src           = "vm_add-rest"
  }

  # Standard GCP scopes for compute instances
  compute_scopes = [
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/trace.append"
  ]

  # Multi-zone deployment flag
  is_multi_zone = length(local.zone_keys) > 1
}
