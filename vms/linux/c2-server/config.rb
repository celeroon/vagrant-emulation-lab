config.vm.define "c2-server-1" do |node|
  node.vm.guest = :debian
  node.vm.box = "generic-x64/debian11"
  node.vm.hostname = "c2-server-1"
  node.vm.provider :libvirt do |domain|
    domain.management_network_mac = "52:54:02:54:00:03"
    domain.cpu_mode = "host-passthrough"
    domain.machine_type = "q35"
    domain.cpus = 4
    domain.memory = 8192
  end
  node.vm.network :private_network,
    libvirt__tunnel_type: "udp",
    libvirt__tunnel_local_ip: "127.1.12.2",
    libvirt__tunnel_local_port: "10112",
    libvirt__tunnel_ip: "127.1.12.1",
    libvirt__tunnel_port: "10112",
    libvirt__iface_name: "eth1",
    auto_config: false
  # node.vm.provision "ansible" do |ansible|
  #   ansible.compatibility_mode  = "2.0"
  #   ansible.inventory_path      = "./ansible/inventory.ini"
  #   ansible.playbook_command    = "./ansible/ansible-venv/bin/ansible-playbook"
  #   ansible.playbook            = "./ansible/playbooks/c2-server-setup.yml"
  #   ansible.config_file         = "./ansible/ansible.cfg"
  #   ansible.verbose             = "v"
  # end
end