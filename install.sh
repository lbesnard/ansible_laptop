#!/usr/bin/env sh

# check the ssh agent in order to clone git repos later on
if [ -z "$SSH_AUTH_SOCK" ] ; then
  eval `ssh-agent -s`
  ssh-add
fi

sudo apt-get install -y git;

sudo apt-get install -y software-properties-common;
sudo apt-add-repository -y ppa:ansible/ansible;
sudo apt-get update;
sudo apt-get install -y ansible;

ansible-pull -U https://github.com/lbesnard/ansible_laptop.git -K -i hosts
