edgerc_section = "<Account section name>"

contract_id = "ctr_contactID"

# Enrollment details
common_name                 = "<comman_name>"
allow_duplicate_common_name = false
sans                        = ["example.com", "example1.com"]
secure_network              = "<standard-tls/enhanced-tls>"
sni_only                    = true
acknowledge_pre_verification_warnings = true
auto_approve_warnings       = []

# Admin contact
admin_contact = {
  first_name       = "<name>"
  last_name        = "<last name>"
  organization     = ""
  email            = "<email for notifications>"
  phone            = "<contact details>"
  address_line_one = "" 
  address_line_two = ""
  city             = ""
  region           = ""
  postal_code      = ""
  country_code     = ""
}

# CSR details
csr = {
  country_code        = "<country code here>"
  city                = "<fill city here>"
  organization        = "<org details here>"
  organizational_unit = ""
  state               = "<state name here>"
}

# Network config
network_configuration = {
  disallowed_tls_versions = ["TLSv1", "TLSv1_1"]
  clone_dns_names         = true
  geography               = "core"
  must_have_ciphers       = "ak-akamai-2018q3"
  ocsp_stapling           = "on"
  preferred_ciphers       = "ak-akamai-2018q3"
  quic_enabled            = true
}

signature_algorithm = ""

# Tech contact
tech_contact = {
  first_name       = "<fill name here>"
  last_name        = "<last name>"
  organization     = ""
  email            = "<email for notifications>"
  phone            = "<contact details>"
  address_line_one = ""
  city             = ""
  region           = ""
  postal_code      = ""
  country_code     = ""
}

# Organization
organization = {
   name             = "Akamai"
  phone            = "080 4600 1000"
  address_line_one = "EGL"
  address_line_two = "Domlur"
  city             = "Bengaluru"
  region           = "Karnataka"
  postal_code      = "560071"
  country_code     = "IN"
}

certificate_chain_type = "default"

#To test and view certificates on the staging network before deploying to production, set the change_management argument to true in this resource.

change_management = true

enrollment_id     = 12345

# Upload Certificate

# ECDSA Certificate files (If there is no certificate to upload, leave the fields blank while maintaining the same format shown below)
certificate_ecdsa_pem = ""

trust_chain_ecdsa_pem = ""

# RSA Certificate files, Provide the signed RSA certificate file name here. You may rename the files as shown below or use the same names as downloaded

certificate_rsa_pem = "rsa_certificate.pem" 

trust_chain_rsa_pem = "rsa_certificate_ca.pem"

# Whether to acknowledge post-verification warnings defined in auto_approve_warnings. Provide true to acknowledge them.

acknowledge_post_verification_warnings = true

# Whether to acknowledge change management. Provide true to acknowledge that testing on staging is complete and to deploy the certificate to production.
#Note: Use only if the change_management argument is set to true

acknowledge_change_management          = true

# Whether to wait for a certificate to be deployed. Provide true to wait for its deployment.

wait_for_deployment                    = true