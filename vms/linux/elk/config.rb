config.vm.define "elk-1" do |node|
  node.vm.guest = :debian
  node.vm.box = "generic-x64/debian11"
  node.vm.hostname = "elk-1"
  node.vm.provider :libvirt do |domain|
    domain.management_network_mac = "52:54:02:54:01:05" # eth0
    domain.cpus = 4
    domain.memory = 16384
    domain.storage :file, :path => 'es-sv-data.qcow2', :size => '100G', :bus => 'virtio', :type => 'qcow2', :discard => 'unmap', :detect_zeroes => 'on'
  end
  node.vm.network :private_network, # eth1 -> ovs-servers-1
    libvirt__tunnel_type: "udp",
    libvirt__tunnel_local_ip: "127.2.55.2",
    libvirt__tunnel_local_port: "10255",
    libvirt__tunnel_ip: "127.2.55.1",
    libvirt__tunnel_port: "10255",
    libvirt__iface_name: "eth1",
    auto_config: false
  # node.vm.provision "ansible" do |ansible|
  #   ansible.compatibility_mode  = "2.0"
  #   ansible.inventory_path      = "./ansible/inventory.ini"
  #   ansible.playbook_command    = "./ansible/ansible-venv/bin/ansible-playbook"
  #   ansible.playbook            = "./ansible/playbooks/elk-setup.yml"
  #   ansible.config_file         = "./ansible/ansible.cfg"
  #   ansible.verbose             = "v"
  # end
end
  