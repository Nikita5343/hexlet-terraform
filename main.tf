terraform {
  required_version = ">= 0.13"

  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
}

provider "yandex" {
  token = var.yc_token
  zone  = var.zone
}

resource "yandex_vpc_network" "default" {
  folder_id = var.folder_id
}

resource "yandex_vpc_subnet" "default" {
  zone           = var.zone
  network_id     = yandex_vpc_network.default.id
  v4_cidr_blocks = ["10.5.0.0/24"]
  folder_id      = var.folder_id
}

resource "yandex_compute_disk" "default" {
  name      = "disk-name"
  type      = "network-ssd"
  zone      = var.zone
  image_id  = var.image_id
  folder_id = var.folder_id

  labels = {
    environment = "test"
  }
}

resource "yandex_compute_instance" "default" {
  name        = var.vm_name
  platform_id = "standard-v1"
  zone        = var.zone
  folder_id   = var.folder_id

  resources {
    cores  = var.vm_cores
    memory = var.vm_memory
  }

  boot_disk {
    disk_id = yandex_compute_disk.default.id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }
}
