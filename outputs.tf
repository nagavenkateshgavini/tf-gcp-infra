output "client_instance_name" {
  value = google_compute_instance.vm_instance.name
}

output "client_instance_zone" {
  value = google_compute_instance.vm_instance.zone
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
