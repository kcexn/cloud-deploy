gcp_project              = "stochastic-394206"
gcp_project_id           = "90260082910"
gcp_service_account_file = "~/.gcp/ansible-stochastic-394206.json"
region                   = "australia-southeast1"
vpc_name                 = "ansible"
vpc_network              = "https://www.googleapis.com/compute/v1/projects/stochastic-394206/global/networks/default"
subnet_cidr              = "10.152.0.0/20"
source_image             = "projects/debian-cloud/global/images/debian-12-bookworm-v20250709"
environment              = "development"
firewall_ports           = ["22", "80", "8080", "443", "6443"]
join_controllers         = true
lb_fixed_ip              = "10.152.0.6"
zone_cidrs = {
  "a" = "10.152.1.0/24"
  "b" = "10.152.2.0/24"
  "c" = "10.152.3.0/24"
}

node_groups = {
  controller = {
    count          = 3
    machine_type   = "e2-medium"
    disk_size_gb   = 40
    disk_type      = "pd-balanced"
    base_name      = "dev-controller"
    base_address   = 10
    can_ip_forward = true
    labels = {
      role = "k8s"
      tier = "controller"
    }
  }
  worker = {
    count          = 3
    machine_type   = "e2-medium"
    disk_size_gb   = 40
    disk_type      = "pd-standard"
    base_name      = "dev-worker"
    base_address   = 11
    can_ip_forward = true
    labels = {
      role = "k8s"
      tier = "worker"
    }
  }
}
