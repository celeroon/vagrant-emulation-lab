def get_host_ip
  begin
    hostname = `hostname -I 2>/dev/null`.strip.split.first
    return hostname unless hostname.nil? || hostname.empty?
  rescue
  end
end

host_ip = get_host_ip

Vagrant.configure("2") do |config|
  config.vm.box_check_update = false
  config.vm.synced_folder ".", "/vagrant", disabled: true
  config.vm.boot_timeout = 1200
  config.ssh.insert_key = false
  config.nfs.verify_installed = false
  config.vm.allow_hosts_modification = true
  config.vm.provider :libvirt do |libvirt|
    libvirt.suspend_mode = "managedsave"
    libvirt.management_network_keep = true
    libvirt.default_prefix = ""
    libvirt.management_network_name = "vagrant-mgmt"
    libvirt.management_network_address = "192.168.225.0/24"
    libvirt.graphics_autoport = "yes"
    libvirt.graphics_ip = host_ip
    libvirt.channel :type => 'unix', :target_type => 'virtio', :target_name => 'org.qemu.guest_agent.0' # Keep the QEMU guest agent channel (virtio):
    libvirt.channel :type => 'spicevmc', :target_type => 'virtio', :target_name => 'com.redhat.spice.0', :disabled => true # Disable the SPICE channel that the box/provider tries to add
  end
  
  Dir.glob("vms/**/config.rb").sort.each do |vm_file|
    eval(File.read(vm_file), binding, vm_file)
  end
end