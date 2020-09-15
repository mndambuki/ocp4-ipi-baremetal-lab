- name: ${host_name}
  role: ${host_role}
  bootMACAddress: ${host_mac}
  bootMode: ${host_boot_mode}
  hardwareProfile: default
  bmc:
    address: ${host_bmc_address}
    username: ${host_bmc_user}
    password: ${host_bmc_pass}
    disableCertificateVerification: ${host_bmc_no_tls}