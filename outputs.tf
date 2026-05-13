output "server_internal_ips" {
  value = [
    for server in yandex_compute_instance.default :
    server.network_interface[0].ip_address
  ]
}

output "server_external_ips" {
  value = [
    for server in yandex_compute_instance.default :
    server.network_interface[0].nat_ip_address
  ]
}
