config.vm.define "sw-branch-1" do |node|
  node.vm.guest = :debian
  node.vm.box = "CumulusVXCommunity/cumulus-vx"
  node.vm.hostname = "sw-branch-1"

  node.vm.provider :libvirt do |domain|
    domain.management_network_mac = "52:54:02:54:00:15" # eth0
    domain.cpu_mode = "host-passthrough"
    domain.machine_type = "q35"
    domain.cpus = 4
    domain.memory = 5120
    domain.nic_adapter_count = 8
  end

  tunnels = [
    { iface: "gi0/1", lip: "127.3.11.2", lport: 10311, rip: "127.3.11.1", rport: 10311 }, # -> cisco router
    { iface: "gi0/2", lip: "127.3.12.1", lport: 10312, rip: "127.3.12.2", rport: 10312 }, # -> LAN host
  ]

  tunnels.each do |t|
    node.vm.network :private_network,
      libvirt__tunnel_type: "udp",
      libvirt__tunnel_local_ip:  t[:lip],
      libvirt__tunnel_local_port: t[:lport],
      libvirt__tunnel_ip:        t[:rip],
      libvirt__tunnel_port:      t[:rport],
      libvirt__iface_name:       t[:iface],
      auto_config: false
  end

  # node.vm.provision "ansible" do |ansible|
  #   ansible.compatibility_mode = "2.0"
  #   ansible.inventory_path     = "./ansible/inventory.ini"
  #   ansible.playbook_command   = "./ansible/ansible-venv/bin/ansible-playbook"
  #   ansible.playbook           = "./ansible/playbooks/cumulus-setup.yml"
  #   ansible.config_file        = "./ansible/ansible.cfg"
  #   ansible.verbose            = "v"
  # end
end
