terraform {
  required_version = ">= 0.13"

  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }

    datadog = {
      source  = "DataDog/datadog"
      version = "~> 3.50"
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
  count = var.server_count

  name      = "disk-${count.index + 1}"
  type      = "network-ssd"
  zone      = var.zone
  image_id  = var.image_id
  size      = var.disk_size
  folder_id = var.folder_id

  labels = {
    environment = "test"
  }
}

resource "yandex_compute_instance" "default" {
  count = var.server_count

  name        = "${var.vm_name}-${count.index + 1}"
  platform_id = "standard-v1"
  zone        = var.zone
  folder_id   = var.folder_id

  resources {
    cores  = var.vm_cores
    memory = var.vm_memory
  }

  boot_disk {
    disk_id = yandex_compute_disk.default[count.index].id
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.default.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"

    user-data = <<-EOF
      #cloud-config
      packages:
        - nginx
      runcmd:
        - systemctl enable nginx
        - systemctl start nginx
        - echo "Hello from ${var.vm_name}-${count.index + 1}" > /var/www/html/index.html
        - DD_API_KEY=${var.datadog_api_key} DD_SITE=${var.datadog_site} DD_AGENT_MAJOR_VERSION=7 bash -c "$(curl -L https://install.datadoghq.com/scripts/install_script_agent7.sh)"
    EOF
  }
}

resource "yandex_lb_target_group" "default" {
  name      = "app-target-group"
  folder_id = var.folder_id

  dynamic "target" {
    for_each = yandex_compute_instance.default

    content {
      subnet_id = yandex_vpc_subnet.default.id
      address   = target.value.network_interface[0].ip_address
    }
  }
}

resource "yandex_lb_network_load_balancer" "default" {
  name      = "app-load-balancer"
  folder_id = var.folder_id

  listener {
    name        = "http-listener"
    port        = 80
    target_port = 80

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.default.id

    healthcheck {
      name = "http-healthcheck"

      http_options {
        port = 80
        path = "/"
      }
    }
  }
}

resource "datadog_monitor" "cpu_monitor" {
  name    = "High CPU usage on app servers"
  type    = "metric alert"
  message = "CPU usage is too high on app servers"

  query = "avg(last_5m):avg:system.cpu.user{*} > 80"

  monitor_thresholds {
    warning  = 60
    critical = 80
  }
}
