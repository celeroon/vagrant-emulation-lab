define_windows_vm = ->(config, spec) do
  config.vm.define spec[:name] do |node|
    node.vm.guest = :windows
    node.vm.box = "windows-11-24h2-amd64"
    node.vm.hostname = spec[:hostname] || spec[:name]
    vm_prefix = spec[:vm_prefix] || spec[:name].upcase

    node.vm.provider "libvirt" do |domain|
      domain.default_prefix = "#{vm_prefix}_"
      domain.management_network_mac = spec[:mgmt_mac]
      domain.cpus = 4
      domain.memory = 8192
      domain.graphics_type = "vnc"
      domain.video_type = "virtio"
      domain.cpu_mode = "host-passthrough"
      domain.machine_type = "q35"
    end

    # UDP tunnels (optional per VM)
    (spec[:tunnels] || []).each do |t|
      node.vm.network :private_network,
        libvirt__tunnel_type:       "udp",
        libvirt__tunnel_local_ip:   t[:lip],
        libvirt__tunnel_local_port: t[:lport],
        libvirt__tunnel_ip:         t[:rip],
        libvirt__tunnel_port:       t[:rport],
        libvirt__iface_name:        t[:iface],
        auto_config: false
    end

    node.vm.communicator = "winrm"
    node.winrm.username  = spec[:winrm_user] || "vagrant"
    node.winrm.password  = spec[:winrm_pass] || "vagrant"
    node.winrm.ssl_peer_verification = false
    node.winrm.port      = spec[:winrm_port] || 5985

    # node.vm.provision "ansible" do |ansible|
    #   ansible.compatibility_mode = "2.0"
    #   ansible.inventory_path     = "./ansible/inventory.ini"
    #   ansible.playbook_command   = "./ansible/ansible-venv/bin/ansible-playbook"
    #   ansible.playbook           = "./ansible/playbooks/win-users-setup.yml"
    #   ansible.config_file        = "./ansible/ansible.cfg"
    #   ansible.verbose            = "v"
    # end
  end
end

windows_vms = [
  {
    name: "win-user-1",
    vm_prefix: "WIN-VM-1",
    mgmt_mac: "52:54:02:54:00:21",
    tunnels: [
      { iface: "Ethernet 1", lip: "127.2.102.2", lport: 12102, rip: "127.2.102.1", rport: 12102 }
    ]
  },
  {
    name: "win-user-2",
    vm_prefix: "WIN-VM-2",
    mgmt_mac: "52:54:02:54:00:22",
    tunnels: [
      { iface: "Ethernet 1", lip: "127.2.103.2", lport: 12103, rip: "127.2.103.1", rport: 12103 }
    ]
  }
]

windows_vms.each { |spec| define_windows_vm.call(config, spec) }