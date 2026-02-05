# TODO:

## Set up HDD passthrough with LUKS2 onto the nas VM
```variables.tf```

```tf
variable "vm_fleet" {
  type = map(object({
    id         = number
    ip         = string
    cores      = number
    memory     = number
    disk_size  = number
    # Add this line for passthrough support
    passthrough_disks = optional(list(string), [])
  }))
  default = {
    "bf-nas-01" = { 
      id = 181, ip = "192.168.8.181", cores = 1, memory = 1024, disk_size = 10,
      passthrough_disks = [
        "/dev/disk/by-id/ata-ST8000VN004-ID1",
        "/dev/disk/by-id/ata-ST8000VN004-ID2",
        "/dev/disk/by-id/ata-ST8000VN004-ID3",
        "/dev/disk/by-id/ata-ST8000VN004-ID4"
      ]
    },
    # ... other nodes stay the same as they'll use the empty default []
  }
}
```

```main.tf```

```tf
resource "proxmox_vm_qemu" "proxmox_vm" {
  for_each = var.vm_fleet
  name     = each.key
  vmid     = each.value.id
  # ... existing config ...

  # Standard OS Disk
  disk {
    size    = "${each.value.disk_size}G"
    type    = "scsi"
    storage = var.datastore_id
  }

  # Dynamic Passthrough Disks
  # This loops through your list and assigns them to scsi1, scsi2, etc.
  dynamic "disk" {
    for_each = each.value.passthrough_disks
    content {
      type    = "scsi"
      storage = "local" # Proxmox requires a storage name, but the 'file' override points to the ID
      file    = disk.value
      size    = "1G" # Size is ignored for passthrough, but required by the provider
    }
  }
}
```

## 🧠 AI Thoughts

Provider Syntax: Since you are using proxmox_virtual_environment_vm, remember that the disk and cpu settings must be inside blocks, not flat arguments.

The SCSI Offset: In the dynamic block, I added ${disk.key + 1}. This is crucial because scsi0 is usually your OS disk. If you start passthrough at scsi0, you'll overwrite your boot drive path in the config.

LUKS Performance: Ensure cpu { type = "host" } is set; otherwise, your NAS will struggle with the encryption overhead.

# Setup CyberPower UPS on Proxmox host

## 🧠 AI Thoughts
* NUT vs. PVE: I recommend using NUT (Network UPS Tools). Install the driver on the Proxmox host to manage the USB connection.

* Automated Shutdown: You can configure Proxmox to trigger a graceful shutdown of all VMs via ssh or pve-manager commands once the battery hits 20%. This is safer than letting the VMs crash.

# Setup remote access
Currently Tailscale is on the ```*-net-01``` VM with subnet routing. If the VM is down, remote access is lost.

Solutions?:
- install tailscale or Proxmox host (don't like it)
- RPI 


## 🧠 AI Thoughts
* Subnet Router Failover: You’re right—if *-net-01 dies, you're locked out.
* High Availability: Since you have multiple nodes, you can run Tailscale on a second VM (e.g., the NAS) as a High Availability (HA) Subnet Router. Tailscale will automatically failover if one goes down.
* The RPi Option: A Raspberry Pi is the "gold standard" out-of-band management. If Proxmox itself hangs, you can still access the network to trigger a hardware reset via a smart plug or IPMI.
* AC power on in the bios should power on when the power is back on. 

# Setup Docker Volume + backups
* See Blog https://blog.gurucomputing.com.au/Homelabbing%20with%20Proxmox/Backing%20up%20Proxmox/

Old docker volumes should be "downloaded"/SCP'd from a different location on the first provisioning.
This is a chicken and egg thing. But each node could have a replica and be used for this?
 
## 🧠 AI Thoughts
* The Chicken & Egg: For the first run, Ansible can check if a volume is empty. If empty, it can rsync from a "Master Backup" (like an S3 bucket or your old laptop).
* Syncthing: Consider running Syncthing across your nodes. It can keep your /var/lib/docker/volumes/ (or specific data paths) in sync across nodes in real-time, making a "replica" node always ready to take over.
* Backups: Look into Restic or Borg. They handle deduplication beautifully for Docker volumes.
