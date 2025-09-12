config.vm.define "vyos-isp-router-1" do |node|
  node.vm.guest = :linux
  node.vm.box   = "vyos/current"

  node.vm.provider :libvirt do |domain|
    domain.management_network_mac = "52:54:02:54:00:09" # eth0
    domain.cpus   = 1
    domain.memory = 1024
  end

  node.vm.network "public_network",
    bridge: "virbr10",
    type:   "bridge",
    dev:    "virbr10",
    auto_config: false

  tunnels = [
    { iface: "eth2", lip: "127.1.10.1", lport: 10110, rip: "127.1.10.2", rport: 10110 }, # -> FortiGate
    { iface: "eth3", lip: "127.1.11.1", lport: 10111, rip: "127.1.11.2", rport: 10111 }, # -> Email
    { iface: "eth4", lip: "127.1.12.1", lport: 10112, rip: "127.1.12.2", rport: 10112 }, # -> C2
    { iface: "eth5", lip: "127.1.13.1", lport: 10113, rip: "127.1.13.2", rport: 10113 }, # -> Payload
    { iface: "eth6", lip: "127.1.14.1", lport: 10114, rip: "127.1.14.2", rport: 10114 }, # -> Kali
    { iface: "eth7", lip: "127.1.15.1", lport: 10115, rip: "127.1.15.2", rport: 10115 }, # -> branch-1 (cat8kv)
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
  #   ansible.playbook           = "./ansible/playbooks/vyos-isp-router-setup.yml"
  #   ansible.config_file        = "./ansible/ansible.cfg"
  #   ansible.verbose            = "v"
  # end
end
