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

  metadata_startup_script = templatefile("${path.module}/startup-script.sh", {
    mysql_user = google_sql_user.sql_db_user.name
    mysql_host = google_sql_database_instance.sql_instance.first_ip_address
    mysql_password = google_sql_user.sql_db_user.password
    mysql_db = google_sql_database.sql_instance_db.name
    log_file = var.log_file
    gcp_project_id = var.project_id
    gcp_pubsub_topic_id = google_pubsub_topic.webapp_pubsub.name
  })

  service_account {
    email  = google_service_account.webapp_service_account.email
    scopes = ["cloud-platform", "https://www.googleapis.com/auth/pubsub"]
  }

  allow_stopping_for_update = true

  depends_on = [
    google_compute_network.webapp_vpc,
    google_compute_subnetwork.webapp,
    google_sql_database_instance.sql_instance,
    google_sql_user.sql_db_user,
    google_project_iam_binding.logging_admin,
    google_project_iam_binding.monitoring_metric_writer
  ]
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

resource "google_compute_firewall" "allow_tcp_single_port" {
  name    = var.allow_tcp_rule_name
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
  rrdatas      = [google_compute_instance.vm_instance.network_interface.0.access_config.0.nat_ip]

  depends_on = [
    google_compute_instance.vm_instance
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
    MAILGUN_DOMAIN = var.mailgun_domain_name
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
