#!/bin/bash

# Download the roles.
ansible-galaxy install --roles-path roles -r requirements.yml

# Download the software package.
./tools/package-download.sh

# Install python3 tool on the remote host.
ansible -i inventory production -b -m raw -a "test -e /usr/bin/python3 || (dnf install -y python3)"

# DevOps
ansible-playbook run.yml -e "env_install_way=file"
