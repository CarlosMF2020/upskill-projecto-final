Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  # Default VM reliability/performance settings for local VirtualBox runs.
  config.vm.boot_timeout = 600

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1024
    vb.cpus = 1
  end

  # Vagrant-cachier settings to speed up provisioning by caching package downloads.
  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
    config.cache.enable :apt
  end
 
  # Automation Server (control node)
  config.vm.define "auto" do |auto|
    auto.vm.hostname = "auto"
    auto.vm.network "private_network", ip: "192.168.10.30"

    auto.vm.provision "shell", path: "scripts/provision/bootstrap_control_node.sh"
  end

  # Infra Server
  config.vm.define "infra" do |infra|
    infra.vm.hostname = "infra"
    infra.vm.network "private_network", ip: "192.168.10.10"

    infra.vm.provision "shell", path: "scripts/provision/bootstrap_nodes.sh"
  end

  # App Server
  config.vm.define "app" do |app|
    app.vm.hostname = "app"
    app.vm.network "private_network", ip: "192.168.10.20"

    app.vm.provision "shell", path: "scripts/provision/bootstrap_nodes.sh"
  end

  # Monitoring Server
  config.vm.define "monitor" do |monitor|
    monitor.vm.hostname = "monitor"
    monitor.vm.network "private_network", ip: "192.168.10.40"

    monitor.vm.provision "shell", path: "scripts/provision/bootstrap_nodes.sh"
  end 
end