config.vm.define "cuckoo3-1" do |node|
  node.vm.guest = :ubuntu
  node.vm.box = "generic/ubuntu2204"
  node.vm.hostname = "cuckoo3"
  node.vm.provider :libvirt do |domain|
    domain.management_network_mac = "52:54:02:54:01:03"
    domain.cpu_mode = "host-passthrough"
    domain.machine_type = "q35"
    domain.cpus = 4
    domain.memory = 12288
    domain.storage :file, :path => 'cuckoo3-data.qcow2', :size => '100G', :bus => 'virtio', :type => 'qcow2', :discard => 'unmap', :detect_zeroes => 'on'
  end
  node.vm.network :private_network, # eth1 -> ovs-servers-1
    libvirt__tunnel_type: "udp",
    libvirt__tunnel_local_ip: "127.2.53.2",
    libvirt__tunnel_local_port: "10253",
    libvirt__tunnel_ip: "127.2.53.1",
    libvirt__tunnel_port: "10253",
    libvirt__iface_name: "eth1",
    auto_config: false
end
