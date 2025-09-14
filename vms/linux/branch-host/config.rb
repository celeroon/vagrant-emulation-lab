config.vm.define "branch-host-1" do |node|
  node.vm.guest = :debian
  node.vm.box = "generic-x64/debian11"
  node.vm.provider :libvirt do |domain|
    domain.management_network_mac = "52:54:02:54:00:29" # int Gi1   
    domain.cpus = 2
    domain.memory = 2048
  end
  node.vm.network :private_network,
    libvirt__tunnel_type: "udp",
    libvirt__tunnel_local_ip: "127.3.12.2",
    libvirt__tunnel_local_port: "10312",
    libvirt__tunnel_ip: "127.3.12.1",
    libvirt__tunnel_port: "10312",
    libvirt__iface_name: "eth1",
    auto_config: false
end
