
## The Stack: Cloud Provider and Main Services
- **Terraform** manages VM provisioning using Proxmox.
- **Ansible** handles configuration management, orchestration, and deployment.
- **Docker** is used for containerized services.
- Additional tools include **Molecule** for testing, **Pylint** for linting, and **Homebrew/Linuxbrew** for package installation.

## The Handover
- **Inventory Automation**: The Ansible inventory is automatically recreated by Terraform.
- A `local_file` resource in Terraform uses the template file `terraform/beefunk/inventory.tftpl` to generate the inventory file (located in `ansible/inventories/`).
- When Terraform changes (such as adding or modifying nodes), re-running Terraform updates the inventory file, which is then used by Ansible when executing playbooks like `setup_homelabs.yml`.

## The "New Server" Workflow
1. **Edit Terraform Configuration**:  
   - In `terraform/beefunk/variables.tf`, add a new entry to the `vm_fleet` map for the new node.
2. **Apply Terraform Changes**:  
   - Run `terraform apply` to provision the new VM and update the Terraform state.
3. **Inventory Regeneration**:  
   - The Terraform `local_file` resource regenerates the Ansible inventory using `inventory.tftpl`.
4. **Ansible Provisioning**:  
   - Run the appropriate playbook (e.g., `ansible-playbook -i ansible/inventories/<project_name>.ini setup_homelabs.yml`) to configure the new node.

## Ansible File Mapping
- **group_vars/ and host_vars/**:  
  - Store variables specific to groups and individual hosts.
- **roles/**:  
  - Contain reusable tasks (e.g., for conda, Docker, and more).
- **Main Playbook (`setup_homelabs.yml`)**:  
  - Orchestrates roles and imports tasks from various files.
- Variables are also defined in `vars.yml` and `vars/paths.yml`, ensuring that configurations cascade correctly to tasks and roles.

## Visual Logic

```mermaid
graph TD;
    A[Terraform State] --> B[Generate Inventory<br>(using inventory.tftpl)];
    B --> C[Ansible Inventory File];
    C --> D[Ansible Playbook Execution];
```

## Naming & Tags
- **Naming Patterns**:
  - Terraform resources use prefixes (e.g., `bf-` for Brownfunk, `bee-` for Beefunk) to indicate node roles.
  - VM names follow a consistent pattern such as `<prefix>-<role>-<index>`.
- **Ansible Groups and Tags**:
  - Inventory groups include `nas_servers`, `media_servers`, `network_servers`, and `dev_servers`.
  - Tags like `docker`, `brew_install`, and `packages` are used to target specific tasks during playbook runs.
- **Key Highlights**:
  - The seamless integration between Terraform and Ansible is powered by the automated regeneration of the inventory.
  - Maintaining consistent naming conventions and proper tagging helps avoid missed dependencies during configuration edits.
