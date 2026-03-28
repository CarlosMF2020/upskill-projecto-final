#!/usr/bin/env bash
set -eu

apt update
apt install -y python3 openssh-server
systemctl enable --now ssh

install -d -m 700 /home/vagrant/.ssh
touch /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
chmod 600 /home/vagrant/.ssh/authorized_keys

if [ -f /vagrant/ansible/keys/ansible_auto.pub ]; then
  grep -qxF "$(cat /vagrant/ansible/keys/ansible_auto.pub)" /home/vagrant/.ssh/authorized_keys || \
    cat /vagrant/ansible/keys/ansible_auto.pub >> /home/vagrant/.ssh/authorized_keys
fi
