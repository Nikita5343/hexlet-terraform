variable "yc_token" {
  type      = string
  sensitive = true
}

variable "folder_id" {
  type = string
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "image_id" {
  type = string
}

variable "vm_name" {
  type    = string
  default = "test"
}

variable "vm_cores" {
  type    = number
  default = 2
}

variable "vm_memory" {
  type    = number
  default = 2
}

variable "disk_size" {
  type    = number
  default = 10
}

variable "server_count" {
  type    = number
  default = 2
}

variable "ssh_public_key" {
  type = string
}

variable "datadog_api_key" {
  type      = string
  sensitive = true
}

variable "datadog_app_key" {
  type      = string
  sensitive = true
}

variable "datadog_site" {
  type    = string
  default = "datadoghq.eu"
}
