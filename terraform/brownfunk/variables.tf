variable "pm_api_url" {
  type = string
}

variable "pm_api_token" {
  type      = string
  sensitive = true
}

variable "tailscale_key" {
  type      = string
  sensitive = true
}

variable "ssh_key" {
  type = string
}

variable "node_name" {
  type    = string
  default = "brownfunk"
}

variable "datastore_id" {
  type    = string
  default = "local-lvm"
}

variable "gateway_ip" {
  type    = string
  default = "192.168.1.1"
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "template_id" {
  type    = number
  default = 9000
}

variable "project_name" {
  type    = string
  default = "brownfunk"
}

variable "vm_username" {
  type    = string
  default = "ubuntu"
}

variable "trusted_net" {
  type    = string
  default = "192.168.1.0/24"
}

variable "tailscale_lxc_ip" {
  type    = string
  default = "192.168.1.199"
}

variable "proxmox_ip" {
  type    = string
  default = "192.168.1.162"
}
variable "vm_fleet" {
  type = map(object({
    id        = number
    ip        = string
    cores     = number
    memory    = number
    disk_size = number
    is_nas        = optional(bool, false)
  }))
  default = {
    "bf-nas-01" = {
      id = 181, ip = "192.168.1.201", cores = 1, memory = 4096, disk_size = 10, is_nas = true,
    }
    "bf-media-01" = {
      id = 182, ip = "192.168.1.202", cores = 4, memory = 8192, disk_size = 100
    }
    "bf-net-01" = {
      id = 183, ip = "192.168.1.203", cores = 1, memory = 2048, disk_size = 15
    }
    "bf-dev-01" = {
      id = 184, ip = "192.168.1.204", cores = 2, memory = 4096, disk_size = 40
    }
  }
} 

variable "passthrough_disks" {
  description = "List of physical disks to pass through to the NAS"
  type = list(object({
    id       = string # The /dev/disk/by-id/... path
    slot     = number # e.g. 1 for scsi1, 2 for scsi2
  }))
  default = [
    {
      id   = "/dev/disk/by-id/usb-WD_Elements_25A3_443748534438384E-0:0"
      slot = 1
    }
    # { id = "/dev/disk/by-id/future-id", slot = 2 }
  ]
}

variable "lxc_fleet" {
  type = map(object({
    id        = number
    ip        = string
    memory    = number
    cores     = number
    disk_size = number
    template  = string # e.g., "local:vztmpl/ubuntu-22.04..."
    type      = string # e.g., "ubuntu"
  }))
  default = {
    "jellyfin" = {
      id        = 300
      ip        = "192.168.1.205"
      memory    = 4096
      cores     = 4
      disk_size = 30
      template  = "local:vztmpl/ubuntu-25.04-standard_25.04-1.1_amd64.tar.zst"
      type      = "ubuntu"
    }
  }
}
