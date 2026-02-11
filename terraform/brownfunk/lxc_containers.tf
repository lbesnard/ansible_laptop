resource "proxmox_virtual_environment_container" "fleet_lxcs" {
  for_each = var.lxc_fleet

  node_name = var.node_name
  vm_id     = each.value.id

  # FIX: Set this to true. This allows the API token to create it.
  unprivileged = true

  initialization {
    hostname = each.key
    
    ip_config {
      ipv4 {
        address = "${each.value.ip}/24"
        gateway = var.gateway_ip
      }
    }

    user_account {
      keys = [var.ssh_key]
    }
  }

  network_interface {
    name   = "eth0"
    bridge = var.network_bridge
  }

  operating_system {
    template_file_id = each.value.template
    type             = each.value.type
  }

  disk {
    datastore_id = "local-lvm"
    size         = each.value.disk_size
  }

  cpu {
    cores = each.value.cores
  }

  memory {
    dedicated = each.value.memory
  }

  # Features needed for NFS mounting and Docker nesting
  features {
    nesting = true
    # mount   = ["nfs", "cifs"] # Change this from "nfs;cifs"
  }

  # Startup order: Starts AFTER the NAS (order 1)
  startup {
    order      = "2"
    up_delay   = "30"
    down_delay = "30"
  }

  # GPU PASSTHROUGH: Injects the iGPU drivers into the LXC config on the host
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "root"
      host        = var.proxmox_ip
      agent       = true
      # This is the "Don't Hang" secret sauce:
      script_path = "/tmp/terraform_ssh.sh"
      timeout     = "2m"
    }
    inline = [
      "echo 'Waiting for Proxmox locks to clear...'",
      "while pct status ${self.vm_id} | grep -q 'locked'; do sleep 2; done",
      
      # 1. Check if 'mount' is already there. If not, add it.
      # We use '>>' to append to the end of the file to avoid messing with existing lines.
      "grep -q 'mount=' /etc/pve/lxc/${self.vm_id}.conf || echo 'features: nesting=1,mount=nfs;cifs' >> /etc/pve/lxc/${self.vm_id}.conf",
      
      # 2. Add GPU Passthrough (only if not already present)
      "grep -q 'dev/dri' /etc/pve/lxc/${self.vm_id}.conf || (echo 'lxc.cgroup2.devices.allow: c 226:0 rwm' >> /etc/pve/lxc/${self.vm_id}.conf && echo 'lxc.cgroup2.devices.allow: c 226:128 rwm' >> /etc/pve/lxc/${self.vm_id}.conf && echo 'lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir' >> /etc/pve/lxc/${self.vm_id}.conf)",
      
      # 3. The 'Clean' Restart
      "echo 'Restarting container...'",
      "pct stop ${self.vm_id} && pct start ${self.vm_id}"
    ]


  }
}

output "lxc_debug_info" {
  value = {
    for name, config in var.lxc_fleet : name => {
      ip       = config.ip
      template = config.template
    }
  }
}
