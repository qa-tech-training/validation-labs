terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "7.7.0"
    }
  }
}

variable "gcp_project" {}
variable "pubkey_path" {}

provider "google" {
  project     = var.gcp_project
  region      = "europe-west1"
}

module "network" {
  source = "./network"
  network_name = "lab4-vpc"
  region = "europe-west1"
  allowed_ports = ["22", "80", "8080", "8081", "10000-11000"]
  ip_cidr_range = "10.0.0.0/24"
}

module "appservers" {
  count = 2
  source = "./instance"
  region = "europe-west1"
  subnet_name = module.network.subnet_name
  machine_type = "e2-standard-2"
  instance_name = "app-server-${count.index}"
  role = "appserver"
  pubkey_path = var.pubkey_path
}

module "proxy" {
  source = "./instance"
  region = "europe-west1"
  subnet_name = module.network.subnet_name
  machine_type = "e2-standard-2"
  instance_name = "proxy-server"
  role = "proxy"
  pubkey_path = var.pubkey_path
}

module "zabbix" {
  source = "./instance"
  region = "europe-west1"
  subnet_name = module.network.subnet_name
  machine_type = "e2-standard-2"
  instance_name = "zabbix-server"
  role = "zabbix"
  pubkey_path = var.pubkey_path
}

