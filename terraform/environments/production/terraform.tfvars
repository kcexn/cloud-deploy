gcp_project              = "stochastic-394206"
gcp_project_id           = "90260082910"
gcp_service_account_file = "~/.gcp/ansible-stochastic-394206.json"
region                   = "us-east1"
vpc_name                 = "ansible"
vpc_network              = "https://www.googleapis.com/compute/v1/projects/stochastic-394206/global/networks/default"
subnet_cidr              = "10.0.3.0/24"
source_image             = "projects/debian-cloud/global/images/debian-12-bookworm-v20250610"
environment              = "production"
machine_type             = "e2-standard-2"

instances = {
  "prod-web-01" = {
    zone_suffix  = "a"
    ansible_host = "10.0.3.10"
  }
  "prod-web-02" = {
    zone_suffix  = "b"
    ansible_host = "10.0.3.11"
  }
  "prod-db-01" = {
    zone_suffix  = "a"
    ansible_host = "10.0.3.20"
  }
  "prod-db-02" = {
    zone_suffix  = "b"
    ansible_host = "10.0.3.21"
  }
}