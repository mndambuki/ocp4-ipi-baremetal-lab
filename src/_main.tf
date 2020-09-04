terraform {
  backend "local" {}
}

provider "libvirt" {
  uri = "qemu:///system"
}

provider "ct" {
  # version = "~> 0.6.1"
}

provider "tls" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.4"
}
