
output "masters" {
  description = "Details about all master machines."
  value = [for i in range(length(hcloud_server.master)) : {
    "name"          = hcloud_server.master[i].name,
    "public_ipv4"   = var.public_ipv4_enabled ? hcloud_server.master[i].ipv4_address : "",
    "internal_ipv4" = hcloud_server.master[i].network.*.ip[0],
    "ssh_command"   = var.bastion_enabled ? "ssh -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -W %h:%p root@${hcloud_server.bastion[0].ipv4_address}' root@${hcloud_server.master[i].network.*.ip[0]}" : "ssh -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR root@${var.public_ipv4_enabled ? hcloud_server.master[i].ipv4_address : hcloud_server.master[i].network.*.ip[0]}"
  }]

  depends_on = [
    null_resource.master_up,
  ]
}

output "workers" {
  description = "Details about all worker machines."
  value = [for i in range(length(hcloud_server.worker)) : {
    "name"          = hcloud_server.worker[i].name,
    "public_ipv4"   = var.public_ipv4_enabled ? hcloud_server.worker[i].ipv4_address : "",
    "internal_ipv4" = hcloud_server.worker[i].network.*.ip[0],
    "ssh_command"   = var.bastion_enabled ? "ssh -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ProxyCommand='ssh -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -W %h:%p root@${hcloud_server.bastion[0].ipv4_address}' root@${hcloud_server.worker[i].network.*.ip[0]}" : "ssh -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR root@${var.public_ipv4_enabled ? hcloud_server.worker[i].ipv4_address : hcloud_server.worker[i].network.*.ip[0]}"
  }]

  depends_on = [
    null_resource.worker_up,
  ]
}

output "load_balancers" {
  description = "Details about the generated load balancers."
  value = {
    "admin" = {
      "public_ipv4"     = "${hcloud_rdns.lb_master_ipv4.ip_address}"
      "public_hostname" = "${hcloud_rdns.lb_master_ipv4.dns_ptr}"
    },
  }
}

output "masters_ready" {
  description = "All master machines are up and running."
  value       = null_resource.master_up
}

output "workers_ready" {
  description = "All worker machines are up and running."
  value       = null_resource.worker_up
}

output "network_name" {
  description = "The name of the generated network."
  value       = hcloud_network.k3s.name
}

output "bastion" {
  description = "Details about the bastion ssh machine."
  value = [for i in range(length(hcloud_server.bastion)) : {
    "name"          = hcloud_server.bastion[i].name,
    "public_ipv4"   = hcloud_server.bastion[0].ipv4_address,
    "internal_ipv4" = hcloud_server.bastion[i].network.*.ip[0],
    "ssh_command"   = "ssh -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR root@${hcloud_server.bastion[0].ipv4_address}"
  }]
}
