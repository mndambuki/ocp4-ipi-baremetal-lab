- name: ${ocp_host_name}
  role: ${ocp_host_role}
  bmc:
    address: ${ocp_host_bmc_protocol}://${ocp_host_bmc_address}
    username: ${ocp_host_bmc_user}
    password: ${ocp_host_bmc_pass}
  bootMACAddress: ${ocp_host_mac}
  hardwareProfile: default
  #bootMode: ${ocp_host_boot_mode}