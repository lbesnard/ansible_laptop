resource "proxmox_virtual_environment_vm" "brownfunk_vms" {
  lifecycle {
    prevent_destroy = true
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



resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tftpl", {
    vms          = var.vm_fleet
    project_name = var.project_name
    trusted_net  = var.trusted_net
  })
  filename = "${path.module}/../../ansible/inventories/${var.project_name}.ini"
}

