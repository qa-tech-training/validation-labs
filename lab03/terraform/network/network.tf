resource "google_compute_network" "lab3-vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "lab3-subnet" {
  name          = "${var.network_name}-subnet"
  ip_cidr_range = var.ip_cidr_range
  region        = var.region
  network       = google_compute_network.lab3-vpc.id
}

resource "google_compute_firewall" "lab3-firewall" {
  name    = "${var.network_name}-firewall"
  network = google_compute_network.lab3-vpc.name

  allow {
    protocol = "tcp"
    ports    = var.allowed_ports
  }

  source_ranges = ["0.0.0.0/0"]
}


