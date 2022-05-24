output "public_ip_address" {
  value = google_compute_instance.ubuntu.network_interface.0.access_config.0.nat_ip
}

output "tls_private_key" {
  value     = tls_private_key.admin.private_key_pem
  sensitive = true
}
