Vagrant.configure("2") do |config|

  config.vm.box = "bento/ubuntu-22.04"

# Infra Server
  config.vm.define "infra" do |infra|
    infra.vm.hostname = "infra"
    infra.vm.network "private_network", ip: "192.168.10.1"
  end

# App Server 
  config.vm.define "app" do |app|
    app.vm.hostname = "app"
    app.vm.network "private_network", ip: "192.168.10.2"

    app.vm.provision "shell", inline: <<-SHELL
      apt update
      apt install -y python3 openssh-server
    SHELL
  end

  # Automation Server
  config.vm.define "auto" do |auto|
    auto.vm.hostname = "auto"
    auto.vm.network "private_network", ip: "192.168.10.3"

    auto.vm.provision "shell", inline: <<-SHELL
      apt update
      apt install -y ansible
    SHELL
  end

  # Monitoring Server
  config.vm.define "monitor" do |monitor|
    monitor.vm.hostname = "monitor"
    monitor.vm.network "private_network", ip: "192.168.10.4"

    monitor.vm.provision "shell", inline: <<-SHELL
      apt update
      apt install -y python3 openssh-server
    SHELL
  end

end