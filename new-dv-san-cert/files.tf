resource "local_file" "dns_challenges_details" {
  content  = module.dv-san-cert.dns_challenges_details
  filename = "${path.root}/certificates/${var.cert_name}/dns_challenges.txt"
}

resource "local_file" "http_challenges_details" {
  content  = module.dv-san-cert.http_challenges_details
  filename = "${path.root}/certificates/${var.cert_name}/http-challenges.txt"
}