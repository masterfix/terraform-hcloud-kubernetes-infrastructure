
resource "hcloud_firewall" "bastion" {
  count = var.bastion_enabled ? 1 : 0
  name  = "${var.cluster_name}-bastion"
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_server" "bastion" {
  count       = var.bastion_enabled ? 1 : 0
  name        = "${var.cluster_name}-bastion"
  image       = var.master_image
  server_type = "cx11"
  location    = data.hcloud_location.master[0].name
  labels = {
    provisioner = "terraform",
  }
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  network {
    network_id = hcloud_network.k3s.id
    ip         = cidrhost(hcloud_network_subnet.k3s.ip_range, 10)
  }
  firewall_ids = [hcloud_firewall.bastion[count.index].id]
  ssh_keys     = [for k in data.hcloud_ssh_keys.existing.ssh_keys : k.id]
  user_data = templatefile("${path.module}/templates/cloud-config-bastion.yaml.tftpl", {
    fqdn = "${var.cluster_name}-bastion.${var.cluster_base_domain}"
  })

  connection {
    host = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "shutdown -r +1"
    ]
  }

  depends_on = [
    hcloud_network_subnet.k3s,
  ]
}

resource "time_sleep" "bastion_reboot_wait" {
  count           = var.bastion_enabled ? 1 : 0
  create_duration = "90s"

  depends_on = [
    hcloud_server.bastion,
  ]
}

resource "null_resource" "bastion_up" {
  count = var.bastion_enabled ? 1 : 0

  connection {
    host = hcloud_server.bastion[count.index].ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "uptime"
    ]
  }

  depends_on = [
    time_sleep.bastion_reboot_wait
  ]
}

resource "hcloud_rdns" "bastion_ipv4" {
  count      = var.bastion_enabled ? 1 : 0
  server_id  = hcloud_server.bastion[count.index].id
  ip_address = hcloud_server.bastion[count.index].ipv4_address
  dns_ptr    = "${hcloud_server.bastion[count.index].name}.${var.cluster_base_domain}"
}

resource "hcloud_rdns" "bastion_ipv6" {
  count      = var.bastion_enabled ? 1 : 0
  server_id  = hcloud_server.bastion[count.index].id
  ip_address = hcloud_server.bastion[count.index].ipv6_address
  dns_ptr    = "${hcloud_server.bastion[count.index].name}.${var.cluster_base_domain}"
}

resource "hetznerdns_record" "bastion_ipv4" {
  count   = var.bastion_enabled ? 1 : 0
  zone_id = data.hetznerdns_zone.cluster.id
  name    = hcloud_server.bastion[count.index].name
  value   = hcloud_server.bastion[count.index].ipv4_address
  type    = "A"
  ttl     = var.dns_ttl
}

resource "hetznerdns_record" "bastion_ipv6" {
  count   = var.bastion_enabled ? 1 : 0
  zone_id = data.hetznerdns_zone.cluster.id
  name    = hcloud_server.bastion[count.index].name
  value   = hcloud_server.bastion[count.index].ipv6_address
  type    = "AAAA"
  ttl     = var.dns_ttl
}

