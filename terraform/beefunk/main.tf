resource "proxmox_virtual_environment_vm" "beefunk_vms" {
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [
      agent,
      clone, 
      # This tells Terraform: "Don't recreate the VM just because it's already cloned"
      # This allows the physical disks to exist at their real size 
      # without Terraform trying to "fix" them back to 8GB
      disk,
    ]
  }

  for_each  = var.vm_fleet
  
  name      = each.key
  node_name = var.node_name
  vm_id     = each.value.id

  serial_device {
    device = "socket"
  }

  clone {
    vm_id = var.template_id
  }

  disk {
    datastore_id = var.datastore_id
    size         = each.value.disk_size
    interface    = "scsi0"
    file_format  = "raw"
  }
  # 2. THE PASSTHROUGH DISKS (Using the BPG official method)
  dynamic "disk" {
    # Since var.passthrough_disks is already a list(object), just use it directly
    for_each = each.value.is_nas ? var.passthrough_disks : []
    
    content {
      datastore_id      = ""       # The "Magic" fix from the BPG docs
      path_in_datastore = disk.value.id
      file_format       = "raw"
      interface         = "scsi${disk.value.slot}"
    }
  }

  cpu {
    type = "host"
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  network_device {
    bridge = var.network_bridge
  }

  agent {
    enabled = true
    timeout = "10s"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.gateway_ip
      }
    }
    user_account {
      username = var.vm_username
      keys     = [var.ssh_key]
    }
  }
}

# Removed for now - killed access to router
# resource "proxmox_virtual_environment_container" "tailscale_bridge" {
#   node_name = var.node_name
#   vm_id     = 200
#
#   initialization {
#     hostname = "tailscale-bridge"
#     ip_config {
#       ipv4 {
#         address = "${var.tailscale_lxc_ip}/24"
#         gateway = var.gateway_ip
#       }
#     }
#     user_account {
#       keys = [var.ssh_key] # Injects your public key into /root/.ssh/authorized_keys
#     }
#   }
# disk {
#     datastore_id = "local-lvm" # or "local-zfs", check your Proxmox sidebar
#     size         = 4          # 4GB is plenty for a Tailscale bridge
#   }
#   network_interface {
#     name = "nic0" # Changed as per your requirement
#     bridge = var.network_bridge
#   }
#
#   operating_system {
#     template_file_id = "local:vztmpl/debian-13-standard_13.1-2_amd64.tar.zst"
#     type             = "debian"
#   }
#
#   # PART 1: Proxmox Host Configuration (TUN Device)
#   provisioner "remote-exec" {
#     connection {
#       type  = "ssh"
#       user  = "root"
#       host  = var.proxmox_ip
#       agent = true # Uses your local SSH agent
#     }
#     inline = [
#       "grep -q 'dev/net/tun' /etc/pve/lxc/${self.vm_id}.conf || echo 'lxc.cgroup2.devices.allow: c 10:200 rwm' >> /etc/pve/lxc/${self.vm_id}.conf",
#       "grep -q 'dev/net/tun' /etc/pve/lxc/${self.vm_id}.conf || echo 'lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file' >> /etc/pve/lxc/${self.vm_id}.conf",
#       # Detach the reboot so SSH can exit cleanly
#       "nohup sh -c 'sleep 2 && pct reboot ${self.vm_id}' > /dev/null 2>&1 &",
#       "sleep 5" 
#     ]
#   }
#
#   # PART 2: Inside the LXC Configuration (Tailscale Setup)
#   provisioner "remote-exec" {
#     connection {
#       type  = "ssh"
#       user  = "root"
#       host  = var.proxmox_ip
#       agent = true
#     }
#     inline = [
#       "grep -q 'dev/net/tun' /etc/pve/lxc/${self.vm_id}.conf || echo 'lxc.cgroup2.devices.allow: c 10:200 rwm' >> /etc/pve/lxc/${self.vm_id}.conf",
#       "grep -q 'dev/net/tun' /etc/pve/lxc/${self.vm_id}.conf || echo 'lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file' >> /etc/pve/lxc/${self.vm_id}.conf",
#       "nohup sh -c 'sleep 2 && pct reboot ${self.vm_id}' > /dev/null 2>&1 &"
#     ]
#   }
#
#   # STEP 2: Software Installation (VISIBLE LOGS)
#   # There are NO sensitive variables here, so you will see apt progress!
#   provisioner "remote-exec" {
#     connection {
#       type    = "ssh"
#       user    = "root"
#       host    = var.tailscale_lxc_ip
#       agent   = true
#       timeout = "5m"
#     }
#     inline = [
#       "echo 'Waiting for network/reboot...'",
#       "until ping -c 1 8.8.8.8 >/dev/null 2>&1; do sleep 2; done",
#       "apt-get update",
#       "apt-get install -y sudo curl",
#       "curl -fsSL https://tailscale.com/install.sh | sh",
#       "echo 'Binary installation finished!'"
#     ]
#   }
#
#   # STEP 3: Tailscale Auth (HIDDEN LOGS)
#   # Only this small part will be suppressed.
#   provisioner "remote-exec" {
#     connection {
#       type  = "ssh"
#       user  = "root"
#       host  = var.tailscale_lxc_ip
#       agent = true
#     }
#     inline = [
#       "tailscale up --authkey=${var.tailscale_key} --advertise-routes=${var.trusted_net} --accept-dns=true"
#     ]
#   }
#

resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    vms          = var.vm_fleet
    lxcs              = var.lxc_fleet
    project_name = var.project_name
    trusted_net  = var.trusted_net
    passthrough_disks = var.passthrough_disks
  })
  filename = "${path.module}/../../ansible/inventories/${var.project_name}.ini"
}


