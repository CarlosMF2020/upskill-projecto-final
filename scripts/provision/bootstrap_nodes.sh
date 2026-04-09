#!/usr/bin/env bash
set -eu

# Install required packages
echo "*** [node] Updating apt cache"
apt update -y

echo "*** [node] Installing Python + OpenSSH server"
apt install -y python3 openssh-server
systemctl enable --now ssh

echo "*** [node] Packages installed successfully"

# Prepare SSH directory structure with correct permissions
install -d -m 700 /home/vagrant/.ssh
touch /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chmod 600 /home/vagrant/.ssh/authorized_keys

# Import public key from control node for Ansible passwordless access
if [ -f /vagrant/ansible/keys/ansible/ansible_auto.pub ]; then
  grep -qxF "$(cat /vagrant/ansible/keys/ansible/ansible_auto.pub)" /home/vagrant/.ssh/authorized_keys || \
    cat /vagrant/ansible/keys/ansible/ansible_auto.pub >> /home/vagrant/.ssh/authorized_keys
fi

echo "*** [node] Bootstrap completed successfully"