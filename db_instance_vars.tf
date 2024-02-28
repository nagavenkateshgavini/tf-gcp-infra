variable "db_tier" {
  description = "db tier eg; t1 micro, large etc.."
  type = string
}

variable "db_availability_type" {
  description = "db availability type"
  type = string
}

variable "db_disk_type" {
  description = "mention db disk type"
  type = string
}

variable "db_disk_size" {
  type = string
}

variable "sql_instance_db_name" {
  type = string
}

variable "db_user_name" {
  type = string
}

variable mysql_version {
  type = string
}
