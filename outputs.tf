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
