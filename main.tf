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
  routing_mode = "REGIONAL"
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
