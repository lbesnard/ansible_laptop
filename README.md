# Ansible - provision laptop


# From scratch with sudo privileges
```bash
curl -L https://raw.githubusercontent.com/lbesnard/ansible_laptop/master/install.sh | bash
```

# Install specific tag with no sudo privileges
```bash

ansible-pull -i hosts -U https://github.com/lbesnard/ansible_laptop.git -t conda
ansible-pull -i hosts -U https://github.com/lbesnard/ansible_laptop.git -t neovim
```

# Run locally

```bash
git clone https://github.com/lbesnard/ansible_laptop.git
cd ansible_laptop

# run as root
ansible-playbook -i hosts local.yml -K

# run as user
ansible-playbook -i hosts local.yml

# run as user with a specific tag
ansible-playbook -i hosts local.yml -t conda
```
