variable "project_id" {
  description = "Pass the Project Id during execution"
  type = string
}

variable "region" {
  description = "region where vpc resides"
  type = string
}

variable "webapp_cidr_range" {
  description = "cidr range for subnets"
  type = string
}

variable "db_cidr_range" {
  description = "cidr range for subnets"
  type = string
}

variable "webapp_route" {
  description = "cidr range for subnet route"
  type = string
}

variable "vpc_name" {
  description = "vpc name"
  type = string
}

variable "webapp_subnet_name" {
  description = "webapp_subnet_name"
  type = string
}

variable "db_subnet_name" {
  description = "db_subnet_name"
  type = string
}

variable "vpc_route_name" {
  description = "vpc route name"
  type = string
}

variable "routing_mode" {
  description = "routing mode when vpc gets created"
  type = string
}

# private service connect variables
variable "private_service_access_name" {
  description = "Private service connect name"
  type = string
}

variable "log_file" {
  description = "log file path for webapp"
  type = string
}
