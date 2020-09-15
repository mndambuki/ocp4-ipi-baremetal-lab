resource "tls_private_key" "redfish" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "redfish" {
  private_key_pem = tls_private_key.redfish.private_key_pem
  key_algorithm   = tls_private_key.redfish.algorithm

  subject {
    common_name         = "Redfish"
    organization        = "OCP"
    organizational_unit = "Baremetal Disconnected"
    country             = "ES"
    locality            = "Madrid"
    province            = "Madrid"
  }

  dns_names = [
    format("redfish.%s", var.dns.domain)
  ]

  ip_addresses = [
    "127.0.0.1",
    var.network_baremetal.gateway
  ]
}

resource "tls_locally_signed_cert" "redfish" {
  cert_request_pem      = tls_cert_request.redfish.cert_request_pem
  ca_cert_pem           = tls_self_signed_cert.ocp_root_ca.cert_pem
  ca_private_key_pem    = tls_private_key.ocp_root_ca.private_key_pem
  ca_key_algorithm      = tls_private_key.ocp_root_ca.algorithm
  validity_period_hours = 8760
  is_ca_certificate     = false
  set_subject_key_id    = true

  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth"
  ]
}

resource "local_file" "redfish_certificate_pem" {
  filename             = "output/tls/clients/redfish/certificate.pem"
  content              = tls_locally_signed_cert.redfish.cert_pem
  file_permission      = "0600"
  directory_permission = "0700"
}

resource "local_file" "redfish_private_key_pem" {
  filename             = "output/tls/clients/redfish/key.pem"
  content              = tls_private_key.redfish.private_key_pem
  file_permission      = "0600"
  directory_permission = "0700"
}
