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
  private_ip_google_access = true
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

resource "random_id" "instance_template_name_suffix" {
  byte_length = 4
}

# Instance template
resource "google_compute_instance_template" "webapp_instance_template" {
  machine_type = var.machine_type

  disk {
    source_image = var.gci
    disk_type = var.instance_disk_type
    disk_size_gb = var.instance_disk_size
    mode = "READ_WRITE"
  }

    metadata_startup_script = templatefile("${path.module}/startup-script.sh", {
    mysql_user = google_sql_user.sql_db_user.name
    mysql_host = google_sql_database_instance.sql_instance.first_ip_address
    mysql_password = google_sql_user.sql_db_user.password
    mysql_db = google_sql_database.sql_instance_db.name
    log_file = var.log_file
    gcp_project_id = var.project_id
    gcp_pubsub_topic_id = google_pubsub_topic.webapp_pubsub.name
  })


  network_interface {
    network = google_compute_network.webapp_vpc.name
    subnetwork = google_compute_subnetwork.webapp.name
  }

  tags = ["webapp"]

  service_account {
    email  = google_service_account.webapp_service_account.email
    scopes = ["cloud-platform", "pubsub"]
  }

  depends_on = [
    google_compute_network.webapp_vpc,
    google_compute_subnetwork.webapp,
    google_sql_database_instance.sql_instance,
    google_sql_user.sql_db_user,
    google_project_iam_binding.logging_admin,
    google_project_iam_binding.monitoring_metric_writer
  ]
}

## Instance healthcheck
resource google_compute_health_check webapp_healthcheck {
  name = var.health_check_name
  check_interval_sec  = 20
  healthy_threshold   = 3
  timeout_sec         = 10
  unhealthy_threshold = 10
  http_health_check {
    request_path = var.healthcheck_endpoint
    port         = var.backend_service_port
  }
  log_config {
    enable = true
  }
}

# Instance group manager
resource google_compute_region_instance_group_manager webapp_instance_group_manager {
  base_instance_name = var.base_instance_name
  name = var.instance_name

  version {
    name = "webapp-user-auth"
    instance_template = google_compute_instance_template.webapp_instance_template.id
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.webapp_healthcheck.id
    initial_delay_sec = 300
  }

  named_port {
    name = "webapp-service-port"
    port = var.backend_service_port
  }

  depends_on = [google_compute_instance_template.webapp_instance_template]
  wait_for_instances = true
}

# Instance autoscaling policy
resource google_compute_region_autoscaler webapp_autoscaler {
  name = var.autoscalar_policy_name
  region = var.region
  autoscaling_policy {
    max_replicas = 2
    min_replicas = 1
    cooldown_period = 60
    cpu_utilization {
      target = var.autoscalar_cpu_utilization
    }
  }
  target = google_compute_region_instance_group_manager.webapp_instance_group_manager.id
  depends_on = [
    google_compute_region_instance_group_manager.webapp_instance_group_manager
  ]
}

# Ingress firewall rule for healthcheck
resource "google_compute_firewall" "default" {
  name          = var.fw_allow_health_check_name
  direction     = "INGRESS"
  network       = google_compute_network.webapp_vpc.id
  priority      = 1000
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["webapp"]

  allow {
    ports    = [var.backend_service_port]
    protocol = "tcp"
  }
}

# global external load balancer

## create ip address
resource "google_compute_global_address" "lb_ip" {
  name       = var.lb_ip_address_name
  ip_version = "IPV4"
}

## create backend service
resource "google_compute_backend_service" "webapp_backend" {
  name = var.backend_service_name
  backend {
    group = google_compute_region_instance_group_manager.webapp_instance_group_manager.instance_group
  }

  health_checks = [google_compute_health_check.webapp_healthcheck.id]
  load_balancing_scheme = "EXTERNAL_MANAGED"
  locality_lb_policy = var.lb_policy
  port_name = "webapp-service-port"
}

## create url map
resource "google_compute_url_map" "webapp_url_map" {
  name = var.url_map_name
  default_service = google_compute_backend_service.webapp_backend.id
}

## create https proxy
resource "google_compute_target_https_proxy" "lb_https_proxy" {
  name     = var.https_proxy_name
  url_map  = google_compute_url_map.webapp_url_map.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.lb_ssl.id
  ]
  depends_on = [
    google_compute_managed_ssl_certificate.lb_ssl
  ]
}

## create forwarding rule
resource "google_compute_global_forwarding_rule" "default" {
  name                  = var.forwarding_rule_name
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.lb_https_proxy.id
  ip_address            = google_compute_global_address.lb_ip.id
}

## create ssl certificate
resource "google_compute_managed_ssl_certificate" "lb_ssl" {
  name = var.ssl_cert_name
  managed {
    domains = [var.domain_name]
  }
}

# create firewall rules
resource "google_compute_firewall" "no_ssh_firewall" {
  name    = var.deny_ssh_rule_name
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

# Private service access to create link between VM and Cloud SQL

# Create an IP address
resource "google_compute_global_address" "private_ip_range" {
  name = var.private_service_access_name
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  prefix_length = 16
  network = google_compute_network.webapp_vpc.id
}

# Create a private connection
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.webapp_vpc.id
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]
  service                 = "servicenetworking.googleapis.com"
  depends_on              = [google_compute_global_address.private_ip_range]
  deletion_policy         = "ABANDON"
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "sql_instance" {
  name = "private-instance-${random_id.db_name_suffix.hex}"
  database_version = var.mysql_version
  region = var.region
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier = var.db_tier
    availability_type = var.db_availability_type
    disk_type = var.db_disk_type
    disk_size = var.db_disk_size

    backup_configuration {
      enabled = true
      binary_log_enabled = true
    }

    ip_configuration {
      ipv4_enabled = false
      private_network = google_compute_network.webapp_vpc.id
      enable_private_path_for_google_cloud_services = true
    }
  }
}

resource "google_compute_network_peering_routes_config" "peering_routes" {
  peering              = google_service_networking_connection.private_vpc_connection.peering
  network              = google_compute_network.webapp_vpc.name
  import_custom_routes = true
  export_custom_routes = true
}

resource "google_sql_database" "sql_instance_db" {
  instance = google_sql_database_instance.sql_instance.name
  name = var.sql_instance_db_name
}

resource "random_password" "db_user_random_password" {
  length = 16
  special          = true
  override_special = "!#$%*()-_=+[]{}<>:?"
}

resource "google_sql_user" "sql_db_user" {
  instance = google_sql_database_instance.sql_instance.name
  name     =  var.db_user_name
  password = random_password.db_user_random_password.result
}

# add or update A record
resource "google_dns_record_set" "a-record" {
  name         = var.dns
  type         = "A"
  ttl          = 300
  managed_zone = var.dns_zone
  rrdatas = [google_compute_global_address.lb_ip.address]

  depends_on = [
    google_compute_backend_service.webapp_backend,
    google_compute_global_address.lb_ip,
    google_compute_target_https_proxy.lb_https_proxy
  ]
}

# Service account creation to create link for the following
# ops agent and logs explorer service

resource "google_service_account" "webapp_service_account" {
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
}

resource "google_project_iam_binding" "logging_admin" {
  project = var.project_id
  role    = "roles/logging.admin"

  members = [
    "serviceAccount:${google_service_account.webapp_service_account.email}",
  ]
}

resource "google_project_iam_binding" "monitoring_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_service_account.webapp_service_account.email}",
  ]
}

resource "google_project_iam_binding" "make_cloud_function_as_cloud_sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.editor"

  members = [
    "serviceAccount:${google_service_account.webapp_service_account.email}",
  ]
}

resource "google_project_iam_binding" "vm_to_publish_message_to_pubsub" {
  project = var.project_id
  role    = "roles/pubsub.publisher"

  members = [
    "serviceAccount:${google_service_account.webapp_service_account.email}",
  ]
}

# Create pubsub topic
resource "google_pubsub_topic" "webapp_pubsub" {
  name = "webapp-pubsub"
  message_retention_duration = "604800s"
}

resource "random_id" "vpc_serverless_access_suffix" {
  byte_length = 4
}

# Create serverless vpc access connector to create link between cloud sql and cloud function
# we are reusing existing IP Address created
resource "google_vpc_access_connector" "cfunc2cloudsql_connector" {
  name = "vpc-con-${random_id.vpc_serverless_access_suffix.hex}"
  ip_cidr_range = "10.8.0.0/28"
  network       = google_compute_network.webapp_vpc.id
}

data "archive_file" "source_code" {
  type        = "zip"
  source_dir  = var.serverless_source_path
  output_path = var.serverless_zip_path
}

# Bucket creation before cloud function
resource "google_storage_bucket" "serverless_bucket" {
  name = var.serverless_bucket_name
  location = var.bucket_location
}

resource "google_storage_bucket_object" "archive" {
  name         = "${data.archive_file.source_code.output_md5}.zip"
  bucket       = google_storage_bucket.serverless_bucket.name
  source       = data.archive_file.source_code.output_path
  content_type = "application/zip"
}

# create cloud function
resource "google_cloudfunctions_function" "function" {
  name        = var.cloud_function_name
  description = "Function to send email verification link to the users"
  runtime     = var.cloud_function_runtime

  available_memory_mb          = var.cloud_function_memory
  source_archive_bucket        = google_storage_bucket.serverless_bucket.name
  source_archive_object        = google_storage_bucket_object.archive.name
  entry_point = var.serverless_entrypoint_function_name

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource = google_pubsub_topic.webapp_pubsub.id
  }

  environment_variables = {
    MYSQL_USER = google_sql_user.sql_db_user.name
    MYSQL_PASSWORD = google_sql_user.sql_db_user.password
    MYSQL_DB = google_sql_database.sql_instance_db.name
    MYSQL_HOST = google_sql_database_instance.sql_instance.first_ip_address

    MAILGUN_API_KEY = var.mailgun_api_key
    MAILGUN_DOMAIN = var.domain_name
  }

  service_account_email = google_service_account.webapp_service_account.email
  depends_on = [
    google_service_account.webapp_service_account,
    google_service_networking_connection.private_vpc_connection,
    google_vpc_access_connector.cfunc2cloudsql_connector,
    google_storage_bucket_object.archive
  ]
  vpc_connector = google_vpc_access_connector.cfunc2cloudsql_connector.id
}
