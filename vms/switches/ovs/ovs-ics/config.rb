config.vm.define "ovs-ics-1" do |node|
    node.vm.guest = :linux
    node.vm.box   = "generic-x64/debian11"
    node.vm.hostname = "ovs-ics-1"
  
    node.vm.provider :libvirt do |domain|
      domain.management_network_mac = "52:54:02:54:01:91" # eth0
      domain.cpus   = 1
      domain.memory = 1024
      domain.nic_adapter_count = 8
    end
  
    tunnels = [
      { iface: "eth1", lip: "127.200.1.2", lport: 12001, rip: "127.200.1.1", rport: 12001 }, # fortigate-ics
      { iface: "eth2", lip: "127.200.2.1", lport: 12002, rip: "127.200.2.2", rport: 12002 }, # simulation 
      { iface: "eth3", lip: "127.200.3.1", lport: 12003, rip: "127.200.3.2", rport: 12003 }, # plc
      { iface: "eth4", lip: "127.200.4.1", lport: 12004, rip: "127.200.4.2", rport: 12004 }, # hmi
      { iface: "eth5", lip: "127.200.5.1", lport: 12005, rip: "127.200.5.2", rport: 12005 }, # kali
      { iface: "eth6", lip: "127.200.6.1", lport: 12006, rip: "127.200.6.2", rport: 12006 }, # malcolm
      { iface: "eth7", lip: "127.200.7.1", lport: 12007, rip: "127.200.7.2", rport: 12007 }, # cybervision
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

    node.vm.network :private_network, # port2 - TAP-SPAN monitor
      :libvirt__network_name => "tap-ics-src",
      :libvirt__forward_mode => "none",
      libvirt__dhcp_enabled: false,
      libvirt__iface_name: "tap-ics-src",
      auto_config: false
  
    # node.vm.provision "ansible" do |ansible|
    #   ansible.compatibility_mode = "2.0"
    #   ansible.inventory_path     = "./ansible/inventory.ini"
    #   ansible.playbook_command   = "./ansible/ansible-venv/bin/ansible-playbook"
    #   ansible.playbook           = "./ansible/playbooks/ovs-setup.yml"
    #   ansible.config_file        = "./ansible/ansible.cfg"
    #   ansible.verbose            = "v"
    # end
  end
