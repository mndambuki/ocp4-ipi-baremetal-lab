apiVersion: v1
metadata:
  name: ${cluster_name}
baseDomain: ${dns_domain}
controlPlane:
  name: master
  hyperthreading: Enabled
  replicas: 3
compute:
  - name: worker
    hyperthreading: Enabled
    replicas: 3
networking:
  networkType: OVNKubernetes
  machineNetwork:
    - cidr: ${nodes_cidr}
  clusterNetwork:
    - cidr: ${pods_cidr}
      hostPrefix: ${pods_range}
  serviceNetwork:
    - ${svcs_cidr}
platform:
  baremetal:
    apiVIP: ${baremetal_api_vip}
    ingressVIP: ${baremetal_ingress_vip}
    externalBridge: ${baremetal_network_baremetal_bridge}
    provisioningNetworkCIDR: ${baremetal_network_provisioning_cidr}
    provisioningBridge: ${baremetal_network_provisioning_bridge}
    provisioningNetworkInterface: ${baremetal_network_provisioning_interface}
    provisioningDHCPExternal: ${baremetal_network_provisioning_dhcp}
    provisioningDHCPRange: ${baremetal_network_provisioning_range}
    hosts:
      ${baremetal_hosts}
pullSecret: '${pull_secret}'
sshKey: '${ssh_pubkey}'
additionalTrustBundle: |
  ${additional_ca}