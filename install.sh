#!/usr/bin/env sh
sudo apt-get install git
sudo apt-get install -y software-properties-common;
sudo apt-add-repository -y ppa:ansible/ansible;
sudo apt-get update;
sudo apt-get install  -y ansible;

ansible-pull -U https://github.com/lbesnard/ansible_laptop.git -K -i hosts
