output "public_key" {
  value = tls_private_key.ssh_key_set.public_key_openssh
}