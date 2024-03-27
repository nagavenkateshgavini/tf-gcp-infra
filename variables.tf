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

variable "cloud_function_memory" {
  description = "memory for your cloud function"
  type = number
}

variable "cloud_function_runtime" {
  description = "Provide runtime for your cloud function code"
  type = string
}

variable "cloud_function_name" {
  description = "Provide cloud function name"
  type = string
}

variable "serverless_source_path" {
  description = "Provide serverless code source path"
  type = string
}

variable "serverless_zip_path" {
  description = "Provide temp path to create archive"
  type = string
}

variable "serverless_bucket_name" {
  description = "Provide bucket name to store serverless code"
  type = string
}

variable "bucket_location" {
  description = "Provide where your bucket should reside"
  type = string
}

variable "local_path_to_serverless_code" {
  description = "Provide local path to your serverless code"
  type = string
}

variable "serverless_entrypoint_function_name" {
  description = "Provide function name of your cloud function"
  type = string
}

variable "mailgun_api_key" {
  description = "Provide mailgun api key to send emails"
  type = string
}

variable "mailgun_domain_name" {
  description = "Provide mailgun domain name"
  type = string
}
