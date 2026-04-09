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

# Configure SSH key permissions for Ansible automation
chown vagrant:vagrant /home/vagrant/.ssh/ansible_auto_ed25519 /home/vagrant/.ssh/ansible_auto_ed25519.pub
chmod 600 /home/vagrant/.ssh/ansible_auto_ed25519
chmod 644 /home/vagrant/.ssh/ansible_auto_ed25519.pub

# Set up authorized_keys for local SSH access
touch /home/vagrant/.ssh/authorized_keys
chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
chmod 600 /home/vagrant/.ssh/authorized_keys
grep -qxF "$(cat /home/vagrant/.ssh/ansible_auto_ed25519.pub)" /home/vagrant/.ssh/authorized_keys || \
    cat /home/vagrant/.ssh/ansible_auto_ed25519.pub >> /home/vagrant/.ssh/authorized_keys

# Generate SSH keys for sysadmin and operator users
for user in sysadmin operator; do
    if [ ! -f /home/vagrant/.ssh/technova_${user} ]; then
        sudo -u vagrant ssh-keygen -t ed25519 -N "" -f /home/vagrant/.ssh/technova_${user} -C "technova-${user}"
    fi
    chown vagrant:vagrant /home/vagrant/.ssh/technova_${user} /home/vagrant/.ssh/technova_${user}.pub
    chmod 600 /home/vagrant/.ssh/technova_${user}
    chmod 644 /home/vagrant/.ssh/technova_${user}.pub
done

# Share public keys with managed nodes via synced folder
install -d -m 755 /vagrant/ansible/keys
install -d -m 755 /vagrant/ansible/keys/ansible
install -d -m 755 /vagrant/ansible/keys/sysadmin
install -d -m 755 /vagrant/ansible/keys/operator
cp /home/vagrant/.ssh/ansible_auto_ed25519.pub /vagrant/ansible/keys/ansible/ansible_auto.pub
cp /home/vagrant/.ssh/technova_sysadmin.pub /vagrant/ansible/keys/sysadmin/technova_sysadmin.pub
cp /home/vagrant/.ssh/technova_operator.pub /vagrant/ansible/keys/operator/technova_operator.pub

# Export private keys to shared folder so the Windows host can use them for direct SSH access
install -d -m 700 /vagrant/ansible/keys/private
cp /home/vagrant/.ssh/technova_sysadmin /vagrant/ansible/keys/private/technova_sysadmin
cp /home/vagrant/.ssh/technova_operator /vagrant/ansible/keys/private/technova_operator
chmod 600 /vagrant/ansible/keys/private/technova_sysadmin
chmod 600 /vagrant/ansible/keys/private/technova_operator

echo "*** [control-node] Bootstrap completed successfully"