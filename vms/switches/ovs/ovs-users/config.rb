config.vm.define "ovs-users-1" do |node|
    node.vm.guest = :linux
    node.vm.box   = "generic-x64/debian11"
    node.vm.hostname = "ovs-users-1"
  
    node.vm.provider :libvirt do |domain|
      domain.management_network_mac = "52:54:02:54:00:13" # eth0
      domain.cpus   = 1
      domain.memory = 1024
      domain.nic_adapter_count = 32
    end
  
    tunnels = [
      { iface: "eth1", lip: "127.2.3.2", lport: 10023, rip: "127.2.3.1", rport: 10023 }, # -> ovs-core-1
      { iface: "eth2", lip: "127.2.102.1", lport: 12102, rip: "127.2.102.2", rport: 12102 }, # win-user-1
      { iface: "eth3", lip: "127.2.103.1", lport: 12103, rip: "127.2.103.2", rport: 12103 }, # 
      { iface: "eth4", lip: "127.2.104.1", lport: 12104, rip: "127.2.104.2", rport: 12104 }, # 
      { iface: "eth5", lip: "127.2.105.1", lport: 12105, rip: "127.2.105.2", rport: 12105 }, # 
      { iface: "eth6", lip: "127.2.106.1", lport: 12106, rip: "127.2.106.2", rport: 12106 }, # 
      { iface: "eth7", lip: "127.2.107.1", lport: 12107, rip: "127.2.107.2", rport: 12107 }, # 
      { iface: "eth8", lip: "127.2.108.1", lport: 12108, rip: "127.2.108.2", rport: 12108 }, # 
      { iface: "eth9", lip: "127.2.109.1", lport: 12109, rip: "127.2.109.2", rport: 12109 }, # 
      { iface: "eth10", lip: "127.2.110.1", lport: 12110, rip: "127.2.110.2", rport: 12110 }, # 
      { iface: "eth11", lip: "127.2.111.1", lport: 12111, rip: "127.2.111.2", rport: 12111 }, # 
      { iface: "eth12", lip: "127.2.112.1", lport: 12112, rip: "127.2.112.2", rport: 12112 }, # 
      { iface: "eth13", lip: "127.2.113.1", lport: 12113, rip: "127.2.113.2", rport: 12113 }, # 
      { iface: "eth14", lip: "127.2.114.1", lport: 12114, rip: "127.2.114.2", rport: 12114 }, # 
      { iface: "eth15", lip: "127.2.115.1", lport: 12115, rip: "127.2.115.2", rport: 12115 }, # 
      { iface: "eth16", lip: "127.2.116.1", lport: 12116, rip: "127.2.116.2", rport: 12116 }, # 
      { iface: "eth17", lip: "127.2.117.1", lport: 12117, rip: "127.2.117.2", rport: 12117 }, # 
      { iface: "eth18", lip: "127.2.118.1", lport: 12118, rip: "127.2.118.2", rport: 12118 }, # 
      { iface: "eth19", lip: "127.2.119.1", lport: 12119, rip: "127.2.119.2", rport: 12119 }, # 
      { iface: "eth20", lip: "127.2.120.1", lport: 12120, rip: "127.2.120.2", rport: 12120 }, # 
      { iface: "eth21", lip: "127.2.121.1", lport: 12121, rip: "127.2.121.2", rport: 12121 }, # 
      { iface: "eth22", lip: "127.2.122.1", lport: 12122, rip: "127.2.122.2", rport: 12122 }, # 
      { iface: "eth23", lip: "127.2.123.1", lport: 12123, rip: "127.2.123.2", rport: 12123 }, # 
      { iface: "eth24", lip: "127.2.124.1", lport: 12124, rip: "127.2.124.2", rport: 12124 }, # 
      { iface: "eth25", lip: "127.2.125.1", lport: 12125, rip: "127.2.125.2", rport: 12125 }, # 
      { iface: "eth26", lip: "127.2.126.1", lport: 12126, rip: "127.2.126.2", rport: 12126 }, # 
      { iface: "eth27", lip: "127.2.127.1", lport: 12127, rip: "127.2.127.2", rport: 12127 }, # 
      { iface: "eth28", lip: "127.2.128.1", lport: 12128, rip: "127.2.128.2", rport: 12128 }, # 
      { iface: "eth29", lip: "127.2.129.1", lport: 12129, rip: "127.2.129.2", rport: 12129 }, # 
      { iface: "eth30", lip: "127.2.130.1", lport: 12130, rip: "127.2.130.2", rport: 12130 }, # NAS
      { iface: "eth31", lip: "127.2.131.1", lport: 12131, rip: "127.2.131.2", rport: 12131 }, # reserved
      { iface: "eth32", lip: "127.2.132.1", lport: 12132, rip: "127.2.132.2", rport: 12132 }, # reserved
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
