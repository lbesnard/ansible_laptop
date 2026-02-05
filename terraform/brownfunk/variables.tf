variable "pm_api_url" {
  type = string
}

variable "pm_api_token" {
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
  default = "192.168.8.1"
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
  default = "192.168.8.0/24"
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
      id = 181, ip = "192.168.8.181", cores = 1, memory = 1024, disk_size = 10
    }
    "bf-media-01" = {
      id = 182, ip = "192.168.8.182", cores = 4, memory = 8192, disk_size = 100
    }
    "bf-net-01" = {
      id = 183, ip = "192.168.8.183", cores = 1, memory = 1024, disk_size = 10
    }
    "bf-dev-01" = {
      id = 184, ip = "192.168.8.184", cores = 2, memory = 4096, disk_size = 40
    }
  }
}
