config.vm.define "branch-router-1" do |node|
  node.vm.guest = :freebsd
  node.vm.box = "cisco-catalyst-8kv"
  node.vm.box_version = "17.10.01a"
  node.vm.provider :libvirt do |domain|
    domain.management_network_mac = "52:54:02:54:00:08" # int Gi1   
    domain.cpus = 2
    domain.memory = 4096
  end
  node.vm.network :private_network, # int Gi2 -> isp-router-1
    libvirt__tunnel_type: "udp",
    libvirt__tunnel_local_ip: "127.1.15.2",
    libvirt__tunnel_local_port: "10115",
    libvirt__tunnel_ip: "127.1.15.1",
    libvirt__tunnel_port: "10115",
    libvirt__iface_name: "Gi2",
    auto_config: false
  node.vm.network :private_network, # int Gi3 -> sw-branch-1
    libvirt__tunnel_type: "udp",
    libvirt__tunnel_local_ip: "127.3.11.1",
    libvirt__tunnel_local_port: "10311",
    libvirt__tunnel_ip: "127.3.11.2",
    libvirt__tunnel_port: "10311",
    libvirt__iface_name: "Gi3",
    auto_config: false
end