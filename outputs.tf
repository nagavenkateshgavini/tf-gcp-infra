output "load_balancer_ip" {
  value = google_compute_global_address.lb_ip.address
}

output "sql_ip" {
  value = google_sql_database_instance.sql_instance.private_ip_address
}

output "sql_user" {
  value = google_sql_user.sql_db_user.name
}

output "sql_password" {
  value     = google_sql_user.sql_db_user.password
  sensitive = true
}

output "sql_db" {
  value = google_sql_database.sql_instance_db.name
}

output "network_id" {
  value = google_compute_network.webapp_vpc.name
}

output "sub_network_id" {
  value = google_compute_subnetwork.webapp.name
}

output "webapp_service_account" {
  value = google_service_account.webapp_service_account.id
}

output "vm_kms_key" {
  value = google_kms_crypto_key.vm_key.id
}

output "instance_group_name" {
  value = google_compute_region_instance_group_manager.webapp_instance_group_manager.name
}