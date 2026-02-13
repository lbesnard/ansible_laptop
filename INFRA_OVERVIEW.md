
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
When adding a new server, it is critical to follow the established naming conventions and understand the purpose of each VM type. The primary types include:
- **NAS Servers** (e.g. `bf-nas-01` or `bee-nas-01`): These nodes handle shared storage with NFS exports and disk passthrough.
- **Media Servers** (e.g. `bf-media-01` or `bee-media-01`): Responsible for managing containerized media services.
- **Network Servers** (e.g. `bf-net-01` or `bee-net-01`): Dedicated to networking, routing, and Tailscale operations.
- **Development Servers** (e.g. `bf-dev-01` or `bee-dev-01`): Provide development environments for various projects.

Each VM entry is defined in Terraform’s `vm_fleet` map with specific parameters such as unique VM IDs, IP addresses, CPU cores, memory allocation, disk sizes, and (for NAS nodes) a flag `is_nas` along with associated physical disks. IP addresses and gateways are preconfigured per environment (e.g., Brownfunk uses gateway `192.168.1.1` while Beefunk uses `192.168.8.1`).

**Steps to add a new server:**
1. **Terraform Variable Update**:
   - Identify the correct environment: edit `terraform/brownfunk/variables.tf` for Brownfunk or `terraform/beefunk/variables.tf` for Beefunk.
   - In the `vm_fleet` map, add a new key following the naming pattern (`bf-<type>-NN` or `bee-<type>-NN`), where `<type>` is one of `nas`, `media`, `net`, or `dev` and `NN` is the next sequential number.
   - Specify the VM parameters (ID, IP, cores, memory, disk size) and set `is_nas=true` if it is a NAS server.
2. **Provisioning**:
   - Run `terraform apply` from the corresponding directory. This updates the Terraform state, provisions the hardware, and regenerates the Ansible inventory via the `inventory.tftpl` template.
   - Note that the IP addresses and gateway configurations are set based on your Terraform variables.
3. **Ansible Inventory & Playbook Execution**:
   - The generated inventory file will be located in `ansible/inventories/` (e.g., `brownfunk.ini`), with VMs grouped under `[nas_servers]`, `[media_servers]`, `[network_servers]`, and `[dev_servers]`.
   - Execute the main playbook:
     ```bash
     ansible-playbook -i ansible/inventories/brownfunk.ini setup_homelabs.yml
     ```
   - This playbook runs tasks defined in `ansible/setup_homelabs.yml`, such as hostname configuration, package installations, Avahi setup, Docker services, and NFS exports.
   
**Additional Considerations**:
- **Naming Conventions**: Use prefixes (`bf-` for Brownfunk, `bee-` for Beefunk) consistently to ensure proper grouping and task execution in Ansible.
- **IP & Gateway Details**: Each VM's IP must be within the defined subnet, and the correct gateway (e.g., `192.168.1.1` or `192.168.8.1`) must be specified. These are validated during provisioning.
- **Server Roles**: Review the tasks in `ansible/setup_homelabs.yml` and the group definitions in `ansible/inventories/brownfunk.ini` to understand each server’s responsibilities.

Following these steps and considerations will ensure a robust process when adding new nodes to your infrastructure.

## VM Roles and Purposes

- **NAS Servers**:  
  These nodes (e.g., `bf-nas-01` or `bee-nas-01`) are dedicated storage providers. They manage NFS exports and disk passthrough of physical disks defined in Terraform. Tasks like configuring `/etc/exports` via the `exports.j2` template and running storage setup playbooks ensure all other nodes can reliably access shared data.

- **Network Servers**:  
  Represented by entries such as `bf-net-01` or `bee-net-01`, these servers are responsible for network services. They configure network routing (e.g., via Tailscale in `ansible/tasks/tailscale.yml`), adjust DNS settings, and serve as gateways for secure data transmission across the infrastructure.

- **Media Servers**:  
  Typical examples include `bf-media-01` (and planned `bee-media-01`). These servers focus on deploying containerized media applications using Docker (see `ansible/tasks/docker_services_up.yml` and related tasks). They also integrate with Homebrew and NFS mounts to access media libraries hosted by the NAS servers.

- **Development Servers**:  
  With names like `bf-dev-01` or `bee-dev-01`, these nodes provide environments tailored for development and testing. They install developer tools, manage dotfiles, and set up necessary packages (via tasks such as `ansible/tasks/packages.yml` and `ansible/tasks/dotfiles.yml`) to support coding and system experimentation.

- **Jellyfin LXC Container**:  
  Deployed as a Linux container (configured in `terraform/beefunk/lxc_containers.tf` and managed by `ansible/tasks/cook_jellyfin.yml`), the Jellyfin container leverages hardware acceleration (e.g., GPU passthrough) to optimize media streaming performance. It runs Jellyfin with tailored NFS mounts from the NAS and is isolated for improved media processing.

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
      A1["Terraform State<br>(brownfunk & beefunk)"]
      A2["Inventory Template<br>(inventory.tftpl)"]
      A1 --> A2
    end
    subgraph Generated Artifacts
      B1["Inventory Files<br>(ansible/inventories/*.ini)"]
      B2["Terraform State Output"]
      A2 --> B1
      A1 --> B2
    end
    subgraph Ansible Execution
      C1["Main Playbook<br>(setup_homelabs.yml)"]
      C2["Roles & Tasks"]
      C3["Vault File<br>(vars/vault.yml)"]
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
