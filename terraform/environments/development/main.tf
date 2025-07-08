terraform {
  required_version = ">= 1.12"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.42.0"
    }
  }
}

provider "google" {
  project     = var.gcp_project
  region      = var.region
  credentials = file(var.gcp_service_account_file)
}

module "gcp_infrastructure" {
  source = "../../modules/gcp-infrastructure"

  gcp_project            = var.gcp_project
  gcp_project_id         = var.gcp_project_id
  region                 = var.region
  vpc_name               = var.vpc_name
  vpc_network            = var.vpc_network
  subnet_cidr            = var.subnet_cidr
  machine_type           = var.machine_type
  source_image           = var.source_image
  disk_size_gb           = var.disk_size_gb
  environment            = var.environment
  instance_tags          = var.instance_tags
  firewall_ports         = var.firewall_ports
  firewall_source_ranges = var.firewall_source_ranges
  instances              = var.instances
}
