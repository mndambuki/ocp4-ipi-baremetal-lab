ocp_registry = {
  id         = "registry"
  base_img   = "src/storage/images/fedora-coreos-32.20200629.3.0.x86_64.qcow2"
  version    = "2.7.1"
  username   = "ocp"
  password   = "changeme"
  repository = "ocp4/release"
  vcpu       = 2
  memory     = 4096
  size       = 200 # Gigabytes
  port       = 5000
}

ocp_master = {
  id       = "master"
  vcpu     = 4
  memory   = 16384
  size     = 120 # Gigabytes
}

ocp_worker = {
  id       = "worker"
  vcpu     = 4
  memory   = 8192
  size     = 200 # Gigabytes
}
