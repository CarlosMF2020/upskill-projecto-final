#!/usr/bin/env bash
set -eu

# Switch to Portuguese mirror for better reliability
sed -i 's|http://us.archive.ubuntu.com|http://pt.archive.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources
sed -i 's|http://archive.ubuntu.com|http://pt.archive.ubuntu.com|g' /etc/apt/sources.list.d/ubuntu.sources

# Disable apt translations to speed up update
echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/99translations
echo 'Acquire::GzipIndexes "true";' >> /etc/apt/apt.conf.d/99translations

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