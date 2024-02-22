
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


