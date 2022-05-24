resource "tls_private_key" "admin" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}
