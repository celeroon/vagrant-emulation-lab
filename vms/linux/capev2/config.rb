config.vm.define "capev2-1" do |node|
  node.vm.guest = :ubuntu
  node.vm.box = "joaobrlt/ubuntu-desktop-24.04"
  node.vm.hostname = "capev2"
  node.vm.provider :libvirt do |domain|
    domain.management_network_mac = "52:54:02:54:01:04" # eth0
    domain.cpus = 8
    domain.memory = 24576
    domain.storage :file, :path => 'capev2-data.qcow2', :size => '300G', :bus => 'virtio', :type => 'qcow2', :discard => 'unmap', :detect_zeroes => 'on'
  end
  node.vm.network :private_network, # eth1 -> ovs-servers-1
    libvirt__tunnel_type: "udp",
    libvirt__tunnel_local_ip: "127.2.54.2",
    libvirt__tunnel_local_port: "10254",
    libvirt__tunnel_ip: "127.2.54.1",
    libvirt__tunnel_port: "10254",
    libvirt__iface_name: "eth1",
    auto_config: false
end