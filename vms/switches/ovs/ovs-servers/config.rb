config.vm.define "ovs-servers-1" do |node|
    node.vm.guest = :linux
    node.vm.box   = "generic-x64/debian11"
    node.vm.hostname = "ovs-servers-1"
  
    node.vm.provider :libvirt do |domain|
      domain.management_network_mac = "52:54:02:54:00:12" # eth0
      domain.cpus   = 1
      domain.memory = 1024
      domain.nic_adapter_count = 32
    end
  
    tunnels = [
      { iface: "eth1", lip: "127.2.2.2", lport: 10022, rip: "127.2.2.1", rport: 10022 }, # -> ovs-core-1
      { iface: "eth2", lip: "127.2.52.1", lport: 10252, rip: "127.2.52.2", rport: 10252 }, # 
      { iface: "eth3", lip: "127.2.53.1", lport: 10253, rip: "127.2.53.2", rport: 10253 }, # 
      { iface: "eth4", lip: "127.2.54.1", lport: 10254, rip: "127.2.54.2", rport: 10254 }, # 
      { iface: "eth5", lip: "127.2.55.1", lport: 10255, rip: "127.2.55.2", rport: 10255 }, # ELK
      { iface: "eth6", lip: "127.2.56.1", lport: 10256, rip: "127.2.56.2", rport: 10256 }, # DFIR-IRIS
      { iface: "eth7", lip: "127.2.57.1", lport: 10257, rip: "127.2.57.2", rport: 10257 }, # n8n
      { iface: "eth8", lip: "127.2.58.1", lport: 10258, rip: "127.2.58.2", rport: 10258 }, # velociraptor
      { iface: "eth9", lip: "127.2.59.1", lport: 10259, rip: "127.2.59.2", rport: 10259 }, # win-srv-1
      { iface: "eth10", lip: "127.2.60.1", lport: 10260, rip: "127.2.60.2", rport: 10260 }, # 
      { iface: "eth11", lip: "127.2.61.1", lport: 10261, rip: "127.2.61.2", rport: 10261 }, # 
      { iface: "eth12", lip: "127.2.62.1", lport: 10262, rip: "127.2.62.2", rport: 10262 }, # 
      { iface: "eth13", lip: "127.2.63.1", lport: 10263, rip: "127.2.63.2", rport: 10263 }, # 
      { iface: "eth14", lip: "127.2.64.1", lport: 10264, rip: "127.2.64.2", rport: 10264 }, # 
      { iface: "eth15", lip: "127.2.65.1", lport: 10265, rip: "127.2.65.2", rport: 10265 }, # 
      { iface: "eth16", lip: "127.2.66.1", lport: 10266, rip: "127.2.66.2", rport: 10266 }, # 
      { iface: "eth17", lip: "127.2.67.1", lport: 10267, rip: "127.2.67.2", rport: 10267 }, # 
      { iface: "eth18", lip: "127.2.68.1", lport: 10268, rip: "127.2.68.2", rport: 10268 }, # 
      { iface: "eth19", lip: "127.2.69.1", lport: 10269, rip: "127.2.69.2", rport: 10269 }, # 
      { iface: "eth20", lip: "127.2.70.1", lport: 10270, rip: "127.2.70.2", rport: 10270 }, # 
      { iface: "eth21", lip: "127.2.71.1", lport: 10271, rip: "127.2.71.2", rport: 10271 }, # 
      { iface: "eth22", lip: "127.2.72.1", lport: 10272, rip: "127.2.72.2", rport: 10272 }, # 
      { iface: "eth23", lip: "127.2.73.1", lport: 10273, rip: "127.2.73.2", rport: 10273 }, # 
      { iface: "eth24", lip: "127.2.74.1", lport: 10274, rip: "127.2.74.2", rport: 10274 }, # 
      { iface: "eth25", lip: "127.2.75.1", lport: 10275, rip: "127.2.75.2", rport: 10275 }, # 
      { iface: "eth26", lip: "127.2.76.1", lport: 10276, rip: "127.2.76.2", rport: 10276 }, # 
      { iface: "eth27", lip: "127.2.77.1", lport: 10277, rip: "127.2.77.2", rport: 10277 }, # 
      { iface: "eth28", lip: "127.2.78.1", lport: 10278, rip: "127.2.78.2", rport: 10278 }, # 
      { iface: "eth29", lip: "127.2.79.1", lport: 10279, rip: "127.2.79.2", rport: 10279 }, # 
      { iface: "eth30", lip: "127.2.80.1", lport: 10280, rip: "127.2.80.2", rport: 10280 }, # 
      { iface: "eth31", lip: "127.2.81.1", lport: 10281, rip: "127.2.81.2", rport: 10281 }, # reserved
      { iface: "eth32", lip: "127.2.82.1", lport: 10282, rip: "127.2.82.2", rport: 10282 }, # reserved
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
