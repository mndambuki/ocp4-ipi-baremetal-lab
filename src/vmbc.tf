locals {
  vbmc_masters = {
    ipmi = [
      for index in range(var.ocp_cluster.num_masters) :
        {
          attach = format("vbmc add --address %s --port %s --username %s --password %s --libvirt-uri qemu:///system %s && vbmc start %s",
            local.ocp_master[index].ipmi.ip,
            local.ocp_master[index].ipmi.port,    
            local.ocp_master[index].ipmi.user,
            local.ocp_master[index].ipmi.pass,
            local.ocp_master[index].id,  
            local.ocp_master[index].id
          )
          dettach = format("vbmc delete %s", local.ocp_master[index].id)
        }
    ]
  }
  vbmc_workers = {
    ipmi = [
      for index in range(var.ocp_cluster.num_workers) :
        {
          attach = format("vbmc add --address %s --port %s --username %s --password %s --libvirt-uri qemu:///system %s && vbmc start %s",
            local.ocp_worker[index].ipmi.ip,
            local.ocp_worker[index].ipmi.port,    
            local.ocp_worker[index].ipmi.user,
            local.ocp_worker[index].ipmi.pass,
            local.ocp_worker[index].id,  
            local.ocp_worker[index].id
          )
          dettach = format("vbmc delete %s", local.ocp_worker[index].id)
        }
    ]
  }
}

resource "local_file" "attach_ipmi_hosts" {
  filename             = format("output/vmbc/attach-ipmi-hosts.sh")
  content              = <<-EOF
    #!/usr/bin/env bash
    ${join("\n", local.vbmc_masters.ipmi.*.attach)}
    ${join("\n", local.vbmc_workers.ipmi.*.attach)}
  EOF
  file_permission      = "0700"
  directory_permission = "0700"
}

resource "local_file" "dettach_ipmi_hosts" {
  filename             = format("output/vmbc/dettach-ipmi-hosts.sh")
  content              = <<-EOF
    #!/usr/bin/env bash
    ${join("\n", local.vbmc_masters.ipmi.*.dettach)}
    ${join("\n", local.vbmc_workers.ipmi.*.dettach)}
  EOF
  file_permission      = "0700"
  directory_permission = "0700"
}
