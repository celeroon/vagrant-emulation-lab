config.vm.define "ics-cybervision-1" do |node|
  node.vm.box = "cybervision"
  node.vm.hostname = "ics-cybervision-1"
  node.ssh.insert_key = true
  node.ssh.shell = "/bin/sh"
  node.ssh.username = "root"
  node.ssh.password = "password"
  node.vm.provider :libvirt do |domain|
    domain.management_network_mac = "52:54:02:54:01:97"
    domain.cpu_mode = "host-passthrough"
    domain.machine_type = "q35"
    domain.cpus = 8
    domain.memory = 65536
  end
  node.vm.network :private_network, # port2 - TAP-SPAN monitor
    :libvirt__network_name => "tap-ics-dst-cv",
    :libvirt__forward_mode => "none",
    libvirt__dhcp_enabled: false,
    libvirt__iface_name: "tap-ics-dst-cv",
    auto_config: false
end
