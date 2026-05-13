terraform {
  required_version = ">= 0.13"

  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }

    datadog = {
      source = "DataDog/datadog"
    }
  }
}

provider "yandex" {
  token = var.yc_token
  zone  = var.zone
}

provider "datadog" {
  api_key = var.datadog_api_key
  app_key = var.datadog_app_key
  api_url = "https://api.${var.datadog_site}/"
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
  size      = 10

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

    user-data = <<-EOF
      #cloud-config
      runcmd:
        - DD_API_KEY=${var.datadog_api_key} DD_SITE=${var.datadog_site} DD_AGENT_MAJOR_VERSION=7 bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"
    EOF
  }
}

resource "datadog_monitor" "cpu_monitor" {
  name    = "High CPU usage on ${var.vm_name}"
  type    = "metric alert"
  message = "CPU usage is too high on ${var.vm_name}"

  query = "avg(last_5m):avg:system.cpu.user{host:${var.vm_name}} > 80"

  monitor_thresholds {
    warning  = 60
    critical = 80
  }
}
