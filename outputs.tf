
output "masters" {
  description = "Details about all master machines."
  value = [for i in range(length(hcloud_server.master)) : {
    "name"          = hcloud_server.master[i].name,
    "public_ipv4"   = hcloud_server.master[i].ipv4_address,
    "internal_ipv4" = hcloud_server_network.master[i].ip,
    "ssh_command"   = "ssh -o 'UserKnownHostsFile=/dev/null' -o 'LogLevel ERROR' root@${hcloud_server.master[i].ipv4_address}"
  }]
}

output "workers" {
  description = "Details about all worker machines."
  value = [for i in range(length(hcloud_server.worker)) : {
    "name"          = hcloud_server.worker[i].name,
    "public_ipv4"   = hcloud_server.worker[i].ipv4_address,
    "internal_ipv4" = hcloud_server_network.worker[i].ip,
    "ssh_command"   = "ssh -o 'UserKnownHostsFile=/dev/null' -o 'LogLevel ERROR' root@${hcloud_server.worker[i].ipv4_address}"
  }]
}

output "load_balancers" {
  description = "Details about the generated balancers."
  value = {
    "admin" = {
      "public_ipv4" = "${hcloud_rdns.lb_master_ipv4.ip_address}"
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
