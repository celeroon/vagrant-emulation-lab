config.vm.define "fortigate-ics-1" do |node|
  node.vm.guest = :freebsd
  node.vm.box = "fortinet-fortigate"
  # node.vm.box_version = "7.2.0"
  node.vm.provider :libvirt do |domain|
    domain.management_network_mac = "52:54:02:54:01:90" # port1
    domain.cpu_mode = "host-passthrough"
    domain.machine_type = "q35"
    domain.cpus = 1
    domain.memory = 2048
  end
  node.vm.network :private_network, # port2 - vyos-isp-router-1
    libvirt__tunnel_type: "udp",
    libvirt__tunnel_local_ip: "127.1.16.2",
    libvirt__tunnel_local_port: "10116",
    libvirt__tunnel_ip: "127.1.16.1",
    libvirt__tunnel_port: "10116",
    libvirt__iface_name: "port2",
    auto_config: false
  node.vm.network :private_network, # port3 - sw-ics-1
    :libvirt__tunnel_type => "udp",
    :libvirt__tunnel_local_ip => "127.200.1.1",
    :libvirt__tunnel_local_port => "12001",
    :libvirt__tunnel_ip => "127.200.1.2",
    :libvirt__tunnel_port => "12001",
    :libvirt__iface_name => "port3",
    :auto_config => false
  # node.vm.provision "ansible" do |ansible|
  #   ansible.compatibility_mode  = "2.0"
  #   ansible.inventory_path      = "./ansible/inventory.ini"
  #   ansible.playbook_command    = "./ansible/ansible-venv/bin/ansible-playbook"
  #   ansible.playbook            = "./ansible/playbooks/fortigate-ics-setup.yml"
  #   ansible.config_file         = "./ansible/ansible.cfg"
  #   ansible.verbose             = "v"
  # end
end