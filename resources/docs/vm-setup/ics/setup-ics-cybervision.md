# Setup Cyber Vision VM

This is a specific install, so here I'll describe how to build the box and set up the VM.

At the start you will need:

* VMware ovftool bundle for Linux (in my case VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle)
* Cisco Cyber Vision image (in my case CiscoCyberVision-center-with-DPI-4.0.1.ova)

New versions of Cyber Vision images also come with .qcow2 for KVM, but there are none with DPI.

Install VMware ovftool

```bash
chmod +x VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle
```

```bash
sudo ./VMware-ovftool-4.4.1-16812187-lin.x86_64.bundle
```

Next, extract the OVA file:

```bash
ovftool --lax CiscoCyberVision-center-with-DPI-4.0.1.ova .
```

Convert to qcow2 format

```bash
qemu-img convert -pc -O qcow2 CiscoCyberVision/CiscoCyberVision-disk1.vmdk cybervision.qcow2
```

Move image to the libvirt default storage

```bash
sudo mv cybervision.qcow2 /var/lib/libvirt/images/
```

Modify the file ownership:

```bash
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/cybervision.qcow2
```

Using virsh, let's run the VM to configure it first (both network for management and for mirrored traffic are attached). As a second interface, you can select any one for installation purposes.

```bash
virt-install \
  --connect qemu:///system \
  --name cybervision \
  --memory 65536 \
  --vcpus 8 \
  --disk path=/var/lib/libvirt/images/cybervision.qcow2,bus=virtio \
  --import \
  --os-variant debian10 \
  --network network=vagrant-mgmt,model=virtio \
  --network network=tap-ics-dst,model=virtio \
  --graphics spice,listen=0.0.0.0 \
  --video qxl \
  --channel spicevmc,target_type=virtio,name=com.redhat.spice.0 \
  --noautoconsole
```

Now you can access the cockpit interface or open the VM via virtual manager to configure it:

<div align="center">
    <img alt="ICS Cyber Vision Cockpit" src="/resources/images/ics/ics-cybervision-cockpit.png" width="100%">
</div>

Detailed setup tutorial can be found on [YouTube](https://www.youtube.com/watch?v=2szfZl6MfuA) 

* First you need to accept license and select language
* The node type is Center
* Use DHCP to configure interface
<!-- * Set manual IP address as it will be bind to the mac address in the Vagrantfile configuration: `192.168.225.197/24` with gateway of `192.168.225.1` and DNS `8.8.8.8` -->
* `Administration and the collection networks run on two distinct interfaces ?` -> Yes
* NTP server can be `time.google.com`
* FQDN is default
* Enter root password
* You can exclude networks on the collection interface, or 
* `Please enter the network's address dedicated to the Sensors on the COLLECTION interface` -> erase the network address field
* `Please specify the IP address to configure on the acquisition interface, including the netmask` -> it cannot be empty, so use `172.16.95.13/24`
* Leave defaults 0.0.0.0/0 network

After VM reboot access terminal and provide those commands:

```bash
sudo -i
sbs netconf
```

Select `eth1` interface with option `DPI+Snort port`, no filters (empty field) and reboot

```bash
reboot now 
```

Access Cyber Vision using browser `https://192.168.225.197`, set up a new user, and in the Admin -> Sensor you can enable the mirror interface. 

After the VM reboots, you need to shut it down using virtual manager, cockpit or virsh

```bash
virsh -c qemu:///system shutdown cybervision
```

Create metadata file with content below:

```bash
cat > metadata.json <<EOF
{
  "provider": "libvirt",
  "format": "qcow2",
  "virtual_size": 250
}
EOF
```

Create the Vagrant template

```bash
cat > Vagrantfile <<EOF
Vagrant.configure("2") do |config|
  config.vm.provider :libvirt do |libvirt|
    libvirt.driver = "kvm"
    libvirt.memory = 65536
    libvirt.cpus = 8
  end
end
EOF
```

You may copy or move the Cyber Vision image from libvirt default directory to the local directory to build the Vagrant box

```bash
sudo mv /var/lib/libvirt/images/cybervision.qcow2 .
```

Rename the Cyber Vision image to box.img

```bash
mv cybervision.qcow2 box.img
```

Package all into a Vagrant box

```bash
tar czvf cybervision.box metadata.json Vagrantfile box.img
```

Move box to the libvirt default storage

```bash
sudo mv cybervision.box /var/lib/libvirt/images/
```

Modify the file ownership:

```bash
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/cybervision.box
```

Create another metadata file for Vagrant box in /var/lib/libvirt/images/ with content below:

```bash
sudo tee /var/lib/libvirt/images/cybervision.json > /dev/null <<EOF
{
  "name": "cybervision",
  "description": "This box contains the Cyber Vision VM device.",
  "versions": [
    {
      "version": "4.0.1",
      "providers": [
        {
          "name": "libvirt",
          "url": "file:///var/lib/libvirt/images/cybervision.box"
        }
      ]
    }
  ]
}
EOF
```

Add the Vagrant box to the local inventory:

```bash
vagrant box add --box-version 4.0.1 /var/lib/libvirt/images/cybervision.json
```

Before running the VM, check the [vagrant configuration file](/vms/linux/ics-cybervision/config.rb) to make sure that corect interface is attached

> [!] WARNING
> Make sure to [setup host](/resources/docs/vm-setup/ics/setup-ics-host.md) if you change mirror networks. 

> [!] WARNING
> Make sure you change root password in the [configuration file](/vms/linux/ics-cybervision/config.rb)

Run VM

```bash
vagrant up ics-cybervision-1
```

Now in the Events we can see communication between PLC and HMI

<div align="center">
    <img alt="ICS Cyber Vision Events" src="/resources/images/ics/ics-cybervision-events-1.png" width="100%">
</div>
