gcp_project              = "stochastic-394206"
gcp_project_id           = "90260082910"
gcp_service_account_file = "~/.gcp/ansible-stochastic-394206.json"
region                   = "australia-southeast1"
vpc_name                 = "ansible"
vpc_network              = "https://www.googleapis.com/compute/v1/projects/stochastic-394206/global/networks/default"
subnet_cidr              = "10.152.0.0/20"
source_image             = "projects/debian-cloud/global/images/debian-12-bookworm-v20250610"
environment              = "development"

instances = {
  "dev-01" = {
    zone_suffix  = "a"
    ansible_host = "10.152.1.2"
  }
  "dev-02" = {
    zone_suffix  = "b"
    ansible_host = "10.152.2.2"
  }
  "dev-03" = {
    zone_suffix  = "c"
    ansible_host = "10.152.3.2"
  }
}
