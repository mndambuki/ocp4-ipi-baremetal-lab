# OCP registry
output "ocp_registry" {
  value = {
    fqdn = local.ocp_registry.fqdn
    ip   = local.ocp_registry.ip
    ssh  = format("ssh -i %s maintuser@%s", local_file.ssh_maintuser_private_key.filename, local.ocp_registry.fqdn)
  }
}

# OCP masters
output "ocp_masters" {
  value = {
    fqdn = local.ocp_master.*.fqdn
    ip   = local.ocp_master.*.network_baremetal.ip
    ssh  = formatlist("ssh -i %s core@%s", local_file.ssh_maintuser_private_key.filename, local.ocp_master.*.fqdn)
  }
}

# OCP workers
output "ocp_workers" {
  value = {
    fqdn = local.ocp_worker.*.fqdn
    ip   = local.ocp_worker.*.network_baremetal.ip
    ssh  = formatlist("ssh -i %s core@%s", local_file.ssh_maintuser_private_key.filename, local.ocp_worker.*.fqdn)
  }
}

# OCP endpoints
output "ocp_endpoints" {
  value = {
    api     = format("api.%s", var.dns.domain)
    console = format("console-openshift-console.apps.%s", var.dns.domain)
  }
}
