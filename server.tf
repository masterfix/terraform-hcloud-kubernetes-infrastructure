
locals {
  master_server_name_prefix = "${var.cluster_name}-${var.master_name}"
  worker_server_name_prefix = "${var.cluster_name}-${var.worker_name}"
  reboot_wait_duration      = "90s"
}

resource "hcloud_server" "master" {
  count              = var.master_count
  name               = "${local.master_server_name_prefix}${count.index + 1}"
  image              = var.master_image
  server_type        = var.master_type
  location           = element(data.hcloud_location.master, (count.index) % length(data.hcloud_location.master)).name
  placement_group_id = hcloud_placement_group.master[(count.index) % length(data.hcloud_datacenter.master)].id
  labels = {
    provisioner = "terraform",
    engine      = "k3s",
    node_type   = "control-plane"
  }
  public_net {
    ipv4_enabled = var.public_ipv4_enabled
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.k3s.id
    ip         = cidrhost(hcloud_network_subnet.k3s.ip_range, 201 + count.index)
  }
  firewall_ids = [hcloud_firewall.master.id]
  ssh_keys     = [for k in data.hcloud_ssh_keys.existing.ssh_keys : k.id]
  user_data = templatefile("${path.module}/templates/cloud-config.yaml.tftpl", {
    fqdn = "${local.master_server_name_prefix}${count.index + 1}.${var.cluster_base_domain}"
  })

  connection {
    host         = var.bastion_enabled ? self.network.*.ip[0] : self.ipv4_address
    bastion_host = var.bastion_enabled ? hcloud_server.bastion[0].ipv4_address : ""
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "shutdown -r +1"
    ]
  }

  depends_on = [
    hcloud_network_subnet.k3s,
    null_resource.bastion_up,
  ]
}

resource "hcloud_server" "worker" {
  count              = var.worker_count
  name               = "${local.worker_server_name_prefix}${count.index + 1}"
  image              = var.worker_image
  server_type        = var.worker_type
  location           = element(data.hcloud_location.worker, (count.index) % length(data.hcloud_location.worker)).name
  placement_group_id = hcloud_placement_group.worker[(count.index) % length(data.hcloud_datacenter.worker)].id
  labels = {
    provisioner = "terraform",
    engine      = "k3s",
    node_type   = "agent"
  }
  public_net {
    ipv4_enabled = var.public_ipv4_enabled
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.k3s.id
    ip         = cidrhost(hcloud_network_subnet.k3s.ip_range, 101 + count.index)
  }
  firewall_ids = [hcloud_firewall.worker.id]
  ssh_keys     = [for k in data.hcloud_ssh_keys.existing.ssh_keys : k.id]
  user_data = templatefile("${path.module}/templates/cloud-config.yaml.tftpl", {
    fqdn = "${local.worker_server_name_prefix}${count.index + 1}.${var.cluster_base_domain}"
  })

  connection {
    host         = var.bastion_enabled ? self.network.*.ip[0] : self.ipv4_address
    bastion_host = var.bastion_enabled ? hcloud_server.bastion[0].ipv4_address : ""
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "shutdown -r +1"
    ]
  }

  depends_on = [
    hcloud_network_subnet.k3s,
    null_resource.bastion_up,
  ]
}

resource "time_sleep" "master_reboot_wait" {
  count = var.master_count

  create_duration = local.reboot_wait_duration

  triggers = {
    "server_id" = hcloud_server.master[count.index].id
  }
}

resource "time_sleep" "worker_reboot_wait" {
  count = var.worker_count

  create_duration = local.reboot_wait_duration

  triggers = {
    "server_id" = hcloud_server.worker[count.index].id
  }
}

resource "null_resource" "master_up" {
  count = var.master_count

  triggers = {
    "reboot_time" = time_sleep.master_reboot_wait[count.index].id
  }

  connection {
    host         = var.bastion_enabled ? hcloud_server.master[count.index].network.*.ip[0] : hcloud_server.master[count.index].ipv4_address
    bastion_host = var.bastion_enabled ? hcloud_server.bastion[0].ipv4_address : ""
  }

  provisioner "remote-exec" {
    inline = [
      "uptime"
    ]
  }
}

resource "null_resource" "worker_up" {
  count = var.worker_count

  triggers = {
    "reboot_time" = time_sleep.worker_reboot_wait[count.index].id
  }

  connection {
    host         = var.bastion_enabled ? hcloud_server.worker[count.index].network.*.ip[0] : hcloud_server.worker[count.index].ipv4_address
    bastion_host = var.bastion_enabled ? hcloud_server.bastion[0].ipv4_address : ""
  }

  provisioner "remote-exec" {
    inline = [
      "uptime"
    ]
  }
}

resource "hcloud_rdns" "master_ipv4" {
  count      = var.public_ipv4_enabled ? var.master_count : 0
  server_id  = hcloud_server.master[count.index].id
  ip_address = hcloud_server.master[count.index].ipv4_address
  dns_ptr    = "${hcloud_server.master[count.index].name}.${var.cluster_base_domain}"
}

resource "hcloud_rdns" "worker_ipv4" {
  count      = var.public_ipv4_enabled ? var.worker_count : 0
  server_id  = hcloud_server.worker[count.index].id
  ip_address = hcloud_server.worker[count.index].ipv4_address
  dns_ptr    = "${hcloud_server.worker[count.index].name}.${var.cluster_base_domain}"
}

resource "hetznerdns_record" "master_ipv4" {
  count   = var.public_ipv4_enabled ? var.master_count : 0
  zone_id = data.hetznerdns_zone.cluster.id
  name    = hcloud_server.master[count.index].name
  value   = hcloud_server.master[count.index].ipv4_address
  type    = "A"
  ttl     = var.dns_ttl
}

resource "hetznerdns_record" "worker_ipv4" {
  count   = var.public_ipv4_enabled ? var.worker_count : 0
  zone_id = data.hetznerdns_zone.cluster.id
  name    = hcloud_server.worker[count.index].name
  value   = hcloud_server.worker[count.index].ipv4_address
  type    = "A"
  ttl     = var.dns_ttl
}
