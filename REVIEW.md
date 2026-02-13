# Terraform Review

## 1. Alignment with INFRA_OVERVIEW.md
- **Environment-specific configs**: Terraform modules for `brownfunk` and `beefunk` provision consistent VM definitions, matching documented IP ranges and resource allocations. Inventory generation via `local_file` and `inventory.tftpl` accurately reflects dynamic mapping to Ansible inventory.

## 2. Backend & State Management
- **Local state**: Current configuration uses local Terraform state files, which can lead to conflicts in multi-operator or CI environments.
- **Recommended**: Adopt a remote backend (e.g., Terraform Cloud, S3 with DynamoDB locking, or HashiCorp Consul) to ensure state locking, versioning, and secure storage. This prevents drift and supports collaboration.

## 3. Module & DRY Refactoring
- **Duplication**: The `brownfunk` and `beefunk` directories contain nearly identical resources for VMs and LXC containers.
- **Recommended**: Extract a reusable Terraform module for VM provisioning that parameterizes `vm_fleet`, `lxc_fleet`, and environment-specific variables. This reduces duplication, simplifies future environment additions, and centralizes changes.

## 4. Dynamic Inventory Lifecycle
- **Inventory regeneration**: Terraform writes Ansible inventory via `local_file`, but no automation triggers downstream Ansible runs.
- **Recommended**:
  1. Use a `null_resource` with `triggers = { terraform = timestamp() }` and a provisioner to call `ansible-playbook` after apply.
  2. Or integrate Terraform and Ansible workflows via Terraform Cloud or CI pipelines that consume generated inventory.

## 5. Provider & Version Pinning
- **Provider version**: The `proxmox` provider is pinned at v0.94.0. While pinning is good, consider adding `required_version` constraint for Terraform CLI and tracking provider upgrades.
- **Recommended**: Define `terraform.required_version` in `terraform { }` block, update `required_providers` to latest stable minor versions, and schedule periodic provider audits.

## 6. Resource Consistency & Tagging
- **Naming conventions**: VM names follow documented prefixes. However, tags or labels at the Proxmox VM resource level are not utilized.
- **Recommended**: Use `tags` or custom attributes (if supported by the provider) to annotate VMs with roles (nas, media, net, dev) and environment (brownfunk, beefunk) for easier filtering in the Proxmox UI and API.

## Phase 2: Ansible Quality Audit

| Task Name                              | The Issue                                                                                       | The Fix                                                                                          |
|----------------------------------------|-------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|
| Shell tasks without idempotency guards | Many `shell` or `command` modules lack `creates`, `removes`, or `changed_when: false`, causing repeated execution and slow runs | Add appropriate `creates`/`removes` arguments or set `changed_when: false` to mark tasks as no-op when already applied |
| NFS mounts use default hard mounts     | Media client mounts use default hard mounts, which can hang indefinitely if the NAS is down     | Use `opts: "rw,soft,intr,bg,nfsvers=4.1"` to enable `soft`, `bg`, and appropriate timeouts       |
| LUKS unlock tasks leak secrets         | Passing `luks_password` inline in shell tasks exposes secrets in logs                           | Use `no_log: true` and reference vault-protected vars in templated tasks to hide sensitive data   |
| Proxmox SSH hacks instead of API modules | Using SSH `remote-exec` to edit LXC configs instead of leveraging Ansible Proxmox modules      | Replace SSH hacks with `community.general.proxmox_lxc` (or similar) modules for native resource management |

## Phase 2: VLAN & Router VM Recommendations

| Recommendation      | Details                                                                                                                |
|---------------------|------------------------------------------------------------------------------------------------------------------------|
| Router VM Viability | Leverage nested virtualization to run an OpenWrt or OPNsense VM with 512 MB–1 GB RAM and 1–2 vCPUs using a qcow2 image   |
| Terraform Provision | Add a new `vm_fleet` entry for the router VM in `terraform/<env>/variables.tf` and apply via `terraform apply`        |
| Ansible Setup       | Create `ansible/tasks/router.yml` to install VLAN, WireGuard, and Tailscale; configure VLAN subinterfaces via netplan |
| VPN & Routing       | Advertise VLAN subnets via Tailscale (`--advertise-routes`), configure WireGuard; forward UDP ports 41641 & 51820     |
| Benefits & Risks    | Enables network segmentation and centralized VPN termination; adds complexity and resource overhead; ensure security   |
