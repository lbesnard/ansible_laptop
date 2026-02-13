
## The Stack: Cloud Provider, Provisioning, and Configuration
- **Terraform**: Manages provisioning of VMs and containers on Proxmox. Notice two distinct configurations:
  - **terraform/brownfunk**: Configures the Brownfunk node, handling its VM settings, storage passthrough, and associated parameters.
  - **terraform/beefunk**: Independently provisions the Beefunk node with its own configuration and resource definitions.
- **Ansible**: Orchestrates post-provisioning configuration by generating inventories from Terraform outputs, applying roles, and executing tasks.
- **Docker**: Facilitates running containerized services required by each node.
- Supplementary tools such as **Molecule** for testing, **Pylint** for code quality, and **Homebrew/Linuxbrew** for package management further support the ecosystem.

## The Handover and Automated Inventory Generation
- **Inventory Automation**: 
  - Terraform uses `local_file` resources along with inventory templates (`inventory.tftpl`) to generate inventory files for each environment:
    - **terraform/brownfunk** produces an inventory tailored for the Brownfunk node.
    - **terraform/beefunk** generates its own separate inventory file, ensuring distinct configurations.
- **Vault Integration & Templates**:
  - Sensitive data is managed via Ansible Vault (e.g., `vars/vault.yml`) and injected into playbooks as needed.
  - Inventory templates dynamically embed project-specific variables and secrets, ensuring seamless coordination during deployments.
- Updates (e.g., adding or modifying nodes) automatically trigger inventory regeneration, linking configuration files, templates, and secure vault data.

## The "New Server" Workflow
1. **Terraform Configuration Update**:
   - Edit the appropriate `variables.tf` (in either `terraform/brownfunk` or `terraform/beefunk`) to add a new entry in the `vm_fleet` map.
2. **Provisioning**:
   - Run `terraform apply` to provision the new node. This updates the Terraform state and regenerates the corresponding inventory file.
3. **Inventory Regeneration & Ansible Provisioning**:
   - The updated inventory (from `inventory.tftpl`) is stored under `ansible/inventories/`.
   - Execute the main playbook (e.g., `ansible-playbook -i ansible/inventories/<project_name>.ini setup_homelabs.yml`) to configure the new server.

## Ansible File Mapping and Configuration Structure
- **Variable Organization**: 
  - Core variables are maintained in `vars.yml` and `vars/paths.yml`, ensuring consistency across configurations.
- **Host and Group Variables**:
  - `group_vars/` and `host_vars/` hold environment and node-specific settings.
- **Roles**:
  - Reusable roles (e.g., for Conda, Docker, network services) encapsulate detailed configuration procedures.
- **Playbooks**:
  - The primary playbook (`setup_homelabs.yml`) orchestrates all tasks, while incorporating dependencies from inventory templates, vault files, and role definitions.

## Visual Logic and Dependency Mapping

```mermaid
flowchart TD
    subgraph Terraform Layer
      A1[Terraform State<br>(brownfunk & beefunk)]
      A2[Inventory Template<br>(inventory.tftpl)]
      A1 --> A2
    end
    subgraph Generated Artifacts
      B1[Inventory Files<br>(ansible/inventories/*.ini)]
      B2[Terraform State Output]
      A2 --> B1
      A1 --> B2
    end
    subgraph Ansible Execution
      C1[Main Playbook<br>(setup_homelabs.yml)]
      C2[Roles & Tasks]
      C3[Vault File<br>(vars/vault.yml)]
      B1 --> C1
      C1 --> C2
      C3 --> C2
    end
```

## Naming Conventions and Tagging Strategies
- **Resource Naming**:
  - Terraform enforces naming patterns through prefixes (`bf-` for Brownfunk and `bee-` for Beefunk) and structured names (e.g., `bf-nas-01`, `bee-media-01`).
- **Tagging in Ansible**:
  - Tags such as `docker`, `brew_install`, and `packages` enable precise targeting of tasks.
  - This systematic approach to naming and tagging ensures clarity during troubleshooting and scalability of the infrastructure.

**Important Note**: The clear separation between **brownfunk** and **beefunk** configurations supports independent management and evolution of each node's infrastructure, ensuring that updates in one environment do not inadvertently affect the other.
