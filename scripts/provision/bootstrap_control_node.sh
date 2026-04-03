#!/usr/bin/env bash
set -eu

# Install required packages
echo "*** [control-node] Updating apt cache"
apt-get update -y

echo "*** [control-node] Installing Ansible + OpenSSH server"
apt-get install -y ansible openssh-server
systemctl enable --now ssh

echo "*** [control-node] Packages installed successfully"

# Generate dedicated SSH key for Ansible automation
# Private key stays only on this control node for security
install -d -m 700 /home/vagrant/.ssh
if [ ! -f /home/vagrant/.ssh/ansible_auto_ed25519 ]; then
    sudo -u vagrant ssh-keygen -t ed25519 -N "" -f /home/vagrant/.ssh/ansible_auto_ed25519
fi

# Configure SSH key permissions (private key: 600, public key: 644)
chown vagrant:vagrant /home/vagrant/.ssh/ansible_auto_ed25519 /home/vagrant/.ssh/ansible_auto_ed25519.pub
chmod 600 /home/vagrant/.ssh/ansible_auto_ed25519
chmod 644 /home/vagrant/.ssh/ansible_auto_ed25519.pub

# Set up authorized_keys for local SSH access
touch /home/vagrant/.ssh/authorized_keys
chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
grep -qxF "$(cat /home/vagrant/.ssh/ansible_auto_ed25519.pub)" /home/vagrant/.ssh/authorized_keys || \
    cat /home/vagrant/.ssh/ansible_auto_ed25519.pub >> /home/vagrant/.ssh/authorized_keys

# Share public key with managed nodes via synced folder
install -d -m 755 /vagrant/ansible/keys
cp /home/vagrant/.ssh/ansible_auto_ed25519.pub /vagrant/ansible/keys/ansible_auto.pub

echo "*** [control-node] Bootstrap completed successfully"