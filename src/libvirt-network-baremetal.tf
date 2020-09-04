resource "libvirt_network" "ocp_baremetal" {
  name      = var.network_baremetal.name
  domain    = var.dns.domain
  mode      = "route"
  bridge    = var.network_baremetal.bridge
  mtu       = 1500
  addresses = [ var.network_baremetal.subnet ]
  autostart = true

  dhcp {
    enabled = true
  }

  dns {
    enabled    = true
    local_only = true

    # A records
    hosts {
      hostname = local.ocp_registry.fqdn
      ip       = local.ocp_registry.ip
    }

    hosts {
      hostname = format("api.%s", var.dns.domain)
      ip       = var.ocp_cluster.api_vip
    }

    hosts {
      hostname = format("api-int.%s", var.dns.domain)
      ip       = var.ocp_cluster.api_vip
    }

    # Nodes records
    dynamic "hosts" {
      for_each = local.ocp_master
      content {
        hostname = hosts.value.fqdn
        ip       = hosts.value.network_baremetal.ip
      }
    }

    dynamic "hosts" {
      for_each = local.ocp_worker
      content {
        hostname = hosts.value.fqdn
        ip       = hosts.value.network_baremetal.ip
      }
    }

    # Ingress controller routes
    dynamic "hosts" {
      for_each = [
        "console-openshift-console",
        "oauth-openshift",
        "grafana-openshift-monitoring",
        "prometheus-k8s-openshift-monitoring",
        "alertmanager-main-openshift-monitoring",
        "thanos-querier-openshift-monitoring",
        "downloads-openshift-console"
      ]
      content {
        hostname = format("%s.apps.%s", hosts.value, var.dns.domain)
        ip       = var.ocp_cluster.ingress_vip
      }
    }
  }

  xml {
    xslt = file(format("%s/dhcp/libvirt-dnsmasq.xml", path.module))
  }

  depends_on = [
    local_file.dnsmasq_conf_ocp
  ]
}
