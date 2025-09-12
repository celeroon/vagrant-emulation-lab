config.vm.define "ovs-core-1" do |node|
    node.vm.guest = :linux
    node.vm.box   = "generic-x64/debian11"
    node.vm.hostname = "ovs-core-1"
  
    node.vm.provider :libvirt do |domain|
      domain.management_network_mac = "52:54:02:54:00:11" # eth0
      domain.cpus   = 1
      domain.memory = 1024
      domain.nic_adapter_count = 8
    end
  
    tunnels = [
      { iface: "eth1", lip: "127.2.1.2", lport: 10021, rip: "127.2.1.1", rport: 10021 }, # -> fortigate-1
      { iface: "eth2", lip: "127.2.2.1", lport: 10022, rip: "127.2.2.2", rport: 10022 }, # -> ovs-servers
      { iface: "eth3", lip: "127.2.3.1", lport: 10023, rip: "127.2.3.2", rport: 10023 }, # -> ovs-users
      { iface: "eth4", lip: "127.2.4.1", lport: 10024, rip: "127.2.4.2", rport: 10024 }, # -> ovs-dmz
      { iface: "eth5", lip: "127.2.5.1", lport: 10025, rip: "127.2.5.2", rport: 10025 }, # 
      { iface: "eth6", lip: "127.2.6.1", lport: 10026, rip: "127.2.6.2", rport: 10026 }, # 
      { iface: "eth7", lip: "127.2.7.1", lport: 10027, rip: "127.2.7.2", rport: 10027 }, # reserved
      { iface: "eth8", lip: "127.2.8.1", lport: 10028, rip: "127.2.8.2", rport: 10028 }, # reserved
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
    #   ansible.playbook           = "./ansible/playbooks/ovs-setup.yml"
    #   ansible.config_file        = "./ansible/ansible.cfg"
    #   ansible.verbose            = "v"
    # end
  end
