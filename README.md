# Ansible - provision laptop :computer:

This repo aims at provisionning my personal laptop (debian base with XFCE). It 
actively uses my personal [dotfiles](https://github.com/lbesnard/dotfiles).

It will install:
* i3 windows manager and i3blocks
* Shell tools
  * zsh (via [zplug](https://github.com/zplug/zplug)) powerful bash alternative
  * tmux (via [tpm](https://github.com/tmux-plugins/tpm)) (key binding ctrl-a in host and ctrl-b in guest vi ssh)
  * [fzf](https://github.com/junegunn/fzf) (perform vi ** tab for example)
  * [autojump](https://github.com/wting/autojump) j (z is disabled)
  * [ranger](https://ranger.github.io/) (terminal file manager)
  * find (fd, ag, [ripgrep](https://github.com/BurntSushi/ripgrep))
* [vim-plug](https://github.com/junegunn/vim-plug)
* [neovim](https://github.com/neovim/neovim/) (vim replacement) with its python3 conda environment
* git tools
  * [tig](https://github.com/jonas/tig)
  * [forgit](https://github.com/wfxr/forgit) (```glo```, ```gla```, ```gd```)
* [lnav](https://github.com/tstack/lnav) (log viewer)
* [linuxbrew](https://docs.brew.sh/Homebrew-on-Linux)
* [cheat](https://github.com/chrisallenlane/cheat) (```cheat find```  for example)
* [pgcli](https://www.pgcli.com/) (psql client with fuzzy search)
* [colorls](https://github.com/athityakumar/colorls)
* [powerline fonts](https://github.com/powerline/fonts)
* [nerds-fonts](https://github.com/ryanoasis/nerd-fonts/blob/master/readme.md#font-installation)
* [dotbot](https://github.com/anishathalye/dotbot)
* anaconda3 python environment 

* Work related 
  * git repositories
  * conda environment for data-services
  * NetCDF libraries

Most packages are installed via the debian apt-get tools. However, many get also
installed via Homebrew/Linuxbrew. This way ensures to be able to install software 
and their latest version on various machines were sudo access is not granted

# Installation
## 1.1 install private key
install key (usually ```id_rsa```)to $HOME/.ssh (600)
```bash
chmod 600 ~/.ssh/config
chmod 644 ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/id_rsa
ssh-add
```
## 2. provision localhost debian based machine with Ansible
### 2.1 with sudo privileges

Run the following command in bash. (will install git, ansible; good for a new OS)
```bash
curl -L https://raw.githubusercontent.com/lbesnard/ansible_laptop/master/install.sh | bash
```

OR if ansible is already installed on the machine
```
/usr/bin/ansible-pull -U https://github.com/lbesnard/ansible_laptop.git -K -i hosts local.yml
```

### 2.2 Without sudo (and if ansible priorly installed via linuxbrew)
```bash
ansible-pull -U https://github.com/lbesnard/ansible_laptop.git remote.yml -i hosts
```

### 2.3 Install specific tag with no sudo privileges
```bash

ansible-pull -i hosts -U https://github.com/lbesnard/ansible_laptop.git -t conda
ansible-pull -i hosts -U https://github.com/lbesnard/ansible_laptop.git -t neovim
```

### 2.4 Run locally (examples)
```bash
git clone https://github.com/lbesnard/ansible_laptop.git
cd ansible_laptop

# run as root
/usr/bin/ansible-playbook -i hosts local.yml -K

# run as non sudo user
ansible-playbook -i hosts remote.yml --skip-tags apt
#or
ansible-playbook -i hosts user.yml --skip-tags apt

# run as non sudo user with a specific tag
ansible-playbook -i hosts remote.yml -t conda
# or
ansible-playbook -i hosts user.yml -t conda
```
## 3 Post Installation
install manuall vbox ext pack because of manual licencing
```sudo apt-get install virtualbox-ext-pack```
