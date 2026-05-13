output "wiki_external_ip" {
  value = yandex_compute_instance.vm.network_interface[0].nat_ip_address
}

output "wiki_url" {
  value = "http://${yandex_compute_instance.vm.network_interface[0].nat_ip_address}"
}

output "db_host" {
  value = yandex_mdb_postgresql_cluster.dbcluster.host.0.fqdn
}
