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
  }))
  default = {
    "bf-nas-01" = {
      id = 181, ip = "192.168.1.201", cores = 1, memory = 1024, disk_size = 10
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
