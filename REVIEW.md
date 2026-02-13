# Terraform Review

## 1. Reality Check (Infrastructure vs. INFRA_OVERVIEW.md)
- **Provisioning Scope**: The Terraform files for `brownfunk` and `beefunk` match the high-level description in `INFRA_OVERVIEW.md`: each environment provisions its own VMs, sets IPs, CPU/memory allocation, and includes optional disk passthrough for NAS nodes. Additionally, both generate separate Ansible inventory artifacts.
- **LXC Integration**: The doc references LXC containers for media-serving tasks (e.g., `jellyfin`). The Terraform code indeed creates LXC containers (e.g., `fleet_lxcs` in both `brownfunk` and `beefunk`) and passes advanced features like GPU nesting.

Overall, Terraform is consistent with the overview: it provisions Proxmox VMs, configures disk passthrough where `is_nas=true`, and automatically generates Ansible inventory files.

## 2. Resource Audit (Over-Provisioning Risks)
- **Media VMs**: Some VMs (e.g., `bf-media-01`) have 4 cores and 8–8.2 GB RAM. For a small homelab, that’s moderately large. If the host has limited resources, it might constrain other services. Suggest reviewing resource usage or leveraging dynamic scaling to reclaim resources when not needed.
- **NAS VMs**: Setting 4+ GB RAM for a dedicated NAS might be more than enough in typical hobby setups, but the doc indicates it’s also hosting additional services (like NFS), so 4 GB might be acceptable.
  
If hardware is indeed minimal, consider runtime metrics (CPU utilization, memory usage) and reduce VM specs accordingly.

## 3. State & Scalability (Hand-Off to Ansible)
- **State Logic**: Local state is used for generating inventory, which works when a single operator runs Terraform. However, if multiple team members or remote CI/CD pipelines manage this, a remote backend (e.g., Terraform Cloud, S3) is safer to avoid state drift and concurrency problems.
- **Handoff to Ansible**: Currently, Terraform writes out the dynamic inventory via `local_file` and then relies on manual `ansible-playbook` calls. For better automation:
  1. Use `null_resource` or a post-provisioner within Terraform to trigger `ansible-playbook` automatically after provisioning completes (optionally with a “dry-run” safety).
  2. Or keep the separation but store the generated inventory in a version-controlled or shared artifact location. This ensures consistent inventory usage across teams.

By refining how state is stored and how provisioning transitions to configuration, the solution can become more robust, especially as the environment grows or more operators become involved.

## Phase 2: Ansible Quality Audit

| Task Name                              | The Issue                                                                                       | The Fix                                                                                          |
|----------------------------------------|-------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------|
| Shell tasks without idempotency guards | Many `shell` or `command` modules lack `creates`, `removes`, or `changed_when: false`, causing repeated execution and slow runs | Add appropriate `creates`/`removes` arguments or set `changed_when: false` to mark tasks as no-op when already applied |
| NFS mounts use default hard mounts     | Media client mounts use default hard mounts, which can hang indefinitely if the NAS is down     | Use `opts: "rw,soft,intr,bg,nfsvers=4.1"` to enable `soft`, `bg`, and appropriate timeouts       |
| LUKS unlock tasks leak secrets         | Passing `luks_password` inline in shell tasks exposes secrets in logs                           | Use `no_log: true` and reference vault-protected vars in templated tasks to hide sensitive data   |
| Proxmox SSH hacks instead of API modules | Using SSH `remote-exec` to edit LXC configs instead of leveraging Ansible Proxmox modules      | Replace SSH hacks with `community.general.proxmox_lxc` (or similar) modules for native resource management |
