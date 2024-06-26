
variable "gci" {
  description = "google compute image name"
  type = string
}

variable "instance_disk_size" {
  description = "specify disk size for your instance"
  type = number
}

variable "instance_disk_type" {
  description = "specify disk type for your instance"
  type = string
}

variable "instance_zone" {
  description = "specify zone for your instance"
  type = string
}

variable "machine_type" {
  description = "specify machine type for your instance, eg, e2-standard-2"
  type = string
}

variable "instance_name" {
  description = "specify name for your instance"
  type = string
}

variable "cidr_for_nossh" {
  type = string
}

variable "cidr_for_allow_tcp" {
  type = string
}

variable "deny_ssh_rule_name" {
  description = "deny ssh variable"
  type = string
}

variable "allow_tcp_rule_name" {
  description = "allow tcp firewall rule name"
  type = string
}

variable "dns" {
  description = "dns that you configured"
  type = string
}

variable "dns_zone" {
  description = "dns zone name"
  type = string
}

variable "service_account_id" {
  description = "service account unique ID"
  type = string
}

variable "service_account_display_name" {
  description = "service account display name"
  type = string
}
