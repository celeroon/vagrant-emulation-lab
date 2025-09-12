config.vm.define "ovs-dmz-1" do |node|
    node.vm.guest = :linux
    node.vm.box   = "generic-x64/debian11"
    node.vm.hostname = "ovs-dmz-1"
  
    node.vm.provider :libvirt do |domain|
      domain.management_network_mac = "52:54:02:54:00:14" # eth0
      domain.cpus   = 1
      domain.memory = 1024
      domain.nic_adapter_count = 32
    end
  
    tunnels = [
      { iface: "eth1", lip: "127.2.4.2", lport: 10024, rip: "127.2.4.1", rport: 10024 }, # -> ovs-core-1
      { iface: "eth2", lip: "127.2.152.1", lport: 12152, rip: "127.2.152.2", rport: 12152 }, # 
      { iface: "eth3", lip: "127.2.153.1", lport: 12153, rip: "127.2.153.2", rport: 12153 }, # 
      { iface: "eth4", lip: "127.2.154.1", lport: 12154, rip: "127.2.154.2", rport: 12154 }, # 
      { iface: "eth5", lip: "127.2.155.1", lport: 12155, rip: "127.2.155.2", rport: 12155 }, # 
      { iface: "eth6", lip: "127.2.156.1", lport: 12156, rip: "127.2.156.2", rport: 12156 }, # 
      { iface: "eth7", lip: "127.2.157.1", lport: 12157, rip: "127.2.157.2", rport: 12157 }, # 
      { iface: "eth8", lip: "127.2.158.1", lport: 12158, rip: "127.2.158.2", rport: 12158 }, # 
      { iface: "eth9", lip: "127.2.159.1", lport: 12159, rip: "127.2.159.2", rport: 12159 }, # 
      { iface: "eth10", lip: "127.2.160.1", lport: 12160, rip: "127.2.160.2", rport: 12160 }, # 
      { iface: "eth11", lip: "127.2.161.1", lport: 12161, rip: "127.2.161.2", rport: 12161 }, # 
      { iface: "eth12", lip: "127.2.162.1", lport: 12162, rip: "127.2.162.2", rport: 12162 }, # 
      { iface: "eth13", lip: "127.2.163.1", lport: 12163, rip: "127.2.163.2", rport: 12163 }, # 
      { iface: "eth14", lip: "127.2.164.1", lport: 12164, rip: "127.2.164.2", rport: 12164 }, # 
      { iface: "eth15", lip: "127.2.165.1", lport: 12165, rip: "127.2.165.2", rport: 12165 }, # reserved
      { iface: "eth16", lip: "127.2.166.1", lport: 12166, rip: "127.2.166.2", rport: 12166 }, # reserved
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
