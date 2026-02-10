resource "local_file" "csr_ecdsa_file" {
  filename = "${path.root}/certificates/${var.cert_name}/csr_ecdsa.pem"
  content  = module.third-party-cert.csr_ecdsa
}

resource "local_file" "csr_rsa_file" {
  filename = "${path.root}/certificates/${var.cert_name}/csr_rsa.pem"
  content  = module.third-party-cert.csr_rsa
}
