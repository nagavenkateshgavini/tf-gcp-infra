variable "project_id" {
  description = "Pass the Project Id during execution"
  type = string
}

variable "region" {
  description = "region where vpc resides"
  type = string
  default = "us-east1"
}

variable "webapp_cidr_range" {
  description = "cidr range for subnets"
  type = string
  default = "10.0.1.0/24"
}

variable "db_cidr_range" {
  description = "cidr range for subnets"
  type = string
  default = "10.0.2.0/24"
}

variable "webapp_route" {
  description = "cidr range for subnet route"
  type = string
  default = "0.0.0.0/0"
}
