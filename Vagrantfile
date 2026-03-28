Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
 
  # Automation Server (control node)
  config.vm.define "auto" do |auto|
    auto.vm.hostname = "auto"
    auto.vm.network "private_network", ip: "192.168.10.30"

    auto.vm.provision "shell", inline: <<-SHELL
      set -eu
      apt update
      apt install -y ansible openssh-server
      systemctl enable --now ssh

      # Dedicated SSH key for Ansible (private key stays only on auto).
      install -d -m 700 /home/vagrant/.ssh
      if [ ! -f /home/vagrant/.ssh/ansible_auto_ed25519 ]; then
        sudo -u vagrant ssh-keygen -t ed25519 -N "" -f /home/vagrant/.ssh/ansible_auto_ed25519
      fi
      chown vagrant:vagrant /home/vagrant/.ssh/ansible_auto_ed25519 /home/vagrant/.ssh/ansible_auto_ed25519.pub
      chmod 600 /home/vagrant/.ssh/ansible_auto_ed25519
      chmod 644 /home/vagrant/.ssh/ansible_auto_ed25519.pub
      touch /home/vagrant/.ssh/authorized_keys
      chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
      chmod 600 /home/vagrant/.ssh/authorized_keys
      grep -qxF "$(cat /home/vagrant/.ssh/ansible_auto_ed25519.pub)" /home/vagrant/.ssh/authorized_keys || cat /home/vagrant/.ssh/ansible_auto_ed25519.pub >> /home/vagrant/.ssh/authorized_keys

      # Share only public key via synced folder.
      install -d -m 755 /vagrant/ansible/keys
      cp /home/vagrant/.ssh/ansible_auto_ed25519.pub /vagrant/ansible/keys/ansible_auto.pub
    SHELL
  end

  # Infra Server
  config.vm.define "infra" do |infra|
    infra.vm.hostname = "infra"
    infra.vm.network "private_network", ip: "192.168.10.10"

    infra.vm.provision "shell", path: "scripts/provision_remote.sh"
  end

  # App Server
  config.vm.define "app" do |app|
    app.vm.hostname = "app"
    app.vm.network "private_network", ip: "192.168.10.20"

    app.vm.provision "shell", path: "scripts/provision_remote.sh"
  end

  # Monitoring Server
  config.vm.define "monitor" do |monitor|
    monitor.vm.hostname = "monitor"
    monitor.vm.network "private_network", ip: "192.168.10.40"

    monitor.vm.provision "shell", path: "scripts/provision_remote.sh"
  end
end
