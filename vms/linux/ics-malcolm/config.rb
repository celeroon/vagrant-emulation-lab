config.vm.define "ics-malcolm-1" do |node|
  node.vm.box = "generic-x64/debian11"
  node.vm.hostname = "ics-malcolm-1"
  node.vm.provider :libvirt do |domain|
    domain.management_network_mac = "52:54:02:54:01:96"
    domain.cpu_mode = "host-passthrough"
    domain.machine_type = "q35"
    domain.cpus = 16
    domain.memory = 32768
  end
  node.vm.network :private_network, # port2 - TAP-SPAN monitor
    :libvirt__network_name => "tap-ics-dst",
    :libvirt__forward_mode => "none",
    libvirt__dhcp_enabled: false,
    libvirt__iface_name: "tap-ics-dst",
    auto_config: false
  # node.vm.provision "ansible" do |ansible|
  #   ansible.compatibility_mode  = "2.0"
  #   ansible.inventory_path      = "./ansible/inventory.ini"
  #   ansible.playbook_command    = "./ansible/ansible-venv/bin/ansible-playbook"
  #   ansible.playbook            = "./ansible/playbooks/ics-malcolm-setup.yml"
  #   ansible.config_file         = "./ansible/ansible.cfg"
  #   ansible.verbose             = "v"
  # end
end