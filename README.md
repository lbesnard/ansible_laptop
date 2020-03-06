# Ansible - provision laptop

# Examples

## With sudo privileges
```bash
curl -L https://raw.githubusercontent.com/lbesnard/ansible_laptop/master/install.sh | bash

# OR

ansible-pull -U https://github.com/lbesnard/ansible_laptop.git -K -i hosts
```
## Without sudo (and ansible already installed via linuxbrew)
```bash
ansible-pull -U https://github.com/lbesnard/ansible_laptop.git remote.yml -i hosts
```

## Install specific tag with no sudo privileges
```bash

ansible-pull -i hosts -U https://github.com/lbesnard/ansible_laptop.git -t conda
ansible-pull -i hosts -U https://github.com/lbesnard/ansible_laptop.git -t neovim
```

## Run locally

```bash
git clone https://github.com/lbesnard/ansible_laptop.git
cd ansible_laptop

# run as root
ansible-playbook -i hosts local.yml -K

# run as non sudo user
ansible-playbook -i hosts remote.yml --skip-tags apt

# run as non sudo user with a specific tag
ansible-playbook -i hosts remote.yml --skip-tags -t conda
```
