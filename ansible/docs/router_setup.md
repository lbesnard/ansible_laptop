# VM Router Setup Guide

This document walks you through provisioning a VM-based router on Proxmox, installing OpenWrt or OPNsense, configuring VLANs, and setting up WireGuard/Tailscale on a separate VLAN. It also covers Terraform ordering and physical router port forwarding.

## 1. Choose Your Router OS

- **OpenWrt**: lightweight, CLI-oriented, great for embedded or VM installs  
- **OPNsense**: full-featured firewall GUI, more resource-heavy

Recommendation: For a minimal VM, use OpenWrt (<100 MB RAM). If you want a web UI and advanced features, choose OPNsense (512 MB+ RAM).

## 2. Prepare the VM Template

1. Download the ISO image:
   - OpenWrt: https://openwrt.org/downloads  
   - OPNsense: https://opnsense.org/download/  
2. Upload to Proxmox ISO storage (`/var/lib/vz/template/iso/`).

## 3. Terraform: Provision the Router VM

In `terraform/<env>/variables.tf`, add:
```hcl
"bf-router-01" = {
  id        = 190
  ip        = "192.168.1.1"
  cores     = 1
  memory    = 256  # or 512 for OPNsense
  disk_size = 2
  template  = "iso:local:vztmpl/openwrt-22.03.5-x86-64-combined-ext4.img" # or use iso_image for Proxmox VM
}
```
Then in your VM resource:
- Set `ide2 = "local:iso/openwrt-x86-64.iso,media=cdrom"`
- Boot order to boot from CD once, then from disk.

Apply:
```bash
cd terraform/brownfunk && terraform apply
```

## 4. Initial VM Install

1. In Proxmox GUI, start `bf-router-01` VM.
2. Open console, install OS to disk via CLI (OpenWrt) or guided installer (OPNsense).
3. Remove CDISO from VM configuration, reboot.

## 5. Physical Router Port Forwarding

On your upstream physical router:
- Forward UDP 51820 → 192.168.1.1 (WireGuard)
- Forward UDP 41641 → 192.168.1.1 (Tailscale)
- Optionally forward TCP 443 if using HTTPS GUI.

## 6. Ansible: Configure Router Services

Create `ansible/tasks/router.yml` (already added) to:
- Install `vlan`, `wireguard`, `tailscale`
- Enable `8021q` and IPv4 forwarding
- Write Netplan `/etc/netplan/01-vlans.yaml`:
  ```yaml
  network:
    version: 2
    ethernets:
      eth0:
        dhcp4: no
    vlans:
      eth0.10:
        id: 10
        link: eth0
        addresses: ["192.168.10.1/24"]
      eth0.20:
        id: 20
        link: eth0
        addresses: ["192.168.20.1/24"]
  ```
- Apply netplan, bring up Tailscale:
  ```
  tailscale up --authkey=<KEY> \
    --advertise-routes=192.168.10.0/24,192.168.20.0/24 \
    --accept-dns=true
  ```

Run:
```bash
ansible-playbook -i ansible/inventories/brownfunk.ini ansible/tasks/router.yml --limit bf-router-01
```

## 7. VLAN Considerations & Terraform Ordering

- **Order**: Terraform creates VMs in parallel. To ensure router exists before other VMs get VLAN IPs:
  - Add a `null_resource` with a `depends_on = [proxmox_vm.bf-router-01]` trigger before provisioning VLAN-dependent VMs.
  - Or provision router first via `target` flag, then rest in a second apply.

Example:
```hcl
resource "null_resource" "wait_router" {
  depends_on = [proxmox_virtual_environment_vm.bf-router-01]
}

resource "proxmox_virtual_environment_vm" "bf-media-01" {
  depends_on = [null_resource.wait_router]
  # ...
}
```

## 8. GUI vs CLI Management

- **CLI**: SSH into OpenWrt for quick config (`uci`), ideal for scripts.
- **GUI**: Use OPNsense web interface for firewall rules, VLANs, VPN.

## 9. Summary

1. Download ISO, upload to Proxmox.  
2. Terraform provision router VM.  
3. Install OS via console.  
4. Forward ports on physical router.  
5. Run Ansible `router.yml` for VLAN/WG/Tailscale.  
6. Adjust Terraform `depends_on` to enforce ordering.

You now have a segmented homelab network with VLANs, a VM router, and secure VPN routes via Tailscale/WireGuard!
