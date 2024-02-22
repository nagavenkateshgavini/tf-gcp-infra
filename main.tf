terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.15.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region = var.region
}

resource "google_compute_network" "webapp_vpc" {
  name = var.vpc_name
  auto_create_subnetworks = false
  routing_mode = var.routing_mode
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "webapp" {
  ip_cidr_range = var.webapp_cidr_range
  name          = var.webapp_subnet_name
  network       = google_compute_network.webapp_vpc.id
  region        = var.region
}

resource "google_compute_subnetwork" "db" {
  ip_cidr_range = var.db_cidr_range
  name          = var.db_subnet_name
  network       = google_compute_network.webapp_vpc.id
  region        = var.region
}

resource "google_compute_route" "webapp_vpc_route" {
  dest_range = var.webapp_route
  name = var.vpc_route_name
  network = google_compute_network.webapp_vpc.name
  next_hop_gateway = "default-internet-gateway"
}


# compute Instance code starts from here
resource "google_compute_instance" "vm_instance" {
    boot_disk {
      initialize_params {
        image = var.gci
        size  = var.instance_disk_size
        type  = var.instance_disk_type
      }
      mode = "READ_WRITE"
  }


  machine_type = var.machine_type
  name         = var.instance_name

  zone = var.instance_zone
  tags = ["webapp"]

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    network = google_compute_network.webapp_vpc.name
    subnetwork  = google_compute_subnetwork.webapp.name
  }

  depends_on = [
    google_compute_network.webapp_vpc,
    google_compute_subnetwork.webapp
  ]
}

# create firewall rules
resource "google_compute_firewall" "no_ssh_firewall" {
  name    = "no-ssh-firewall"
  network = google_compute_network.webapp_vpc.name

  deny {
    protocol = "tcp"
    ports = ["22"]
  }

  target_tags = [
    "webapp"
  ]

  source_ranges = [var.cidr_for_nossh]
}

resource "google_compute_firewall" "allow_tcp_single_port" {
  name    = "allow-tcp-port"
  network = google_compute_network.webapp_vpc.name

  allow {
    protocol = "tcp"
    ports = ["8000"]
  }

  source_ranges = [var.cidr_for_allow_tcp]
  target_tags = [
    "webapp"
  ]
}

