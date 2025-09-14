# Build Fortinet FortiGate Vagrant (libvirt) box

[Main repo](https://github.com/celeroon/fortigate-vagrant-libvirt)

This stage assumes that the host setup is complete and the required tools are already installed.

## Steps

You need to register a free account on the [Fortinet support website](https://support.fortinet.com/). In Support -> Downloads -> VM Images, you can download FortiGate VM images for versions 7.2, 7.4, and 7.6. This tutorial is based on FortiGate 7.2.0, which supports the older [15-day evaluation license](https://docs.fortinet.com/document/fortigate-private-cloud/7.2.0/microsoft-hyper-v-administration-guide/504166/fortigate-vm-evaluation-license). Starting from 7.2.1, Fortinet introduced a [permanent trial license](https://docs.fortinet.com/document/fortigate/7.2.12/administration-guide/441460) that has more limitations than the 15-day free trial license. To download older FortiGate images, you need access to service contracts. I cannot provide direct links to download the image or show you how to access it for free.

Register an free account and download the FortiGate image for the KVM platform from the [Fortinet support website](https://support.fortinet.com/support/#/downloads/vm). I will test it on the latest available version (7.6.3), but mainly I will work on 7.2.0. When deploying the newer FortiGate version, you will be limited to only one subnet based on the [topology](/resources/images/vagrant-lab-virtual-topology.svg) in this project - all servers and workstations will need to be placed on a single subnet.

When downloading images from the support website, search for `New deployment of FortiGate for KVM`. The image name should look like this: `FGT_VM64_KVM-v7.6.3.F-build3510-FORTINET.out.kvm.zip`.**

Clone the project and enter the directory

```bash
git clone https://github.com/celeroon/fortigate-vagrant-libvirt
cd fortigate-vagrant-libvirt
```

Unzip and move the FortiGate image to the libvirt directory

```bash
sudo unzip -d /var/lib/libvirt/images FGT_VM64_KVM-v7.6.3.F-build3510-FORTINET.out.kvm.zip
```

Modify the file ownership and permissions

```bash
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/fortios.qcow2
sudo chmod u+x /var/lib/libvirt/images/fortios.qcow2
```

Run the Packer build command. If you follow the project recommendations, you will have a DE installed on your Linux host. Running Packer with debug enabled may help you see errors during box creation

```bash
PACKER_LOG=1 packer build -var "version=7.6.3" -var "image_name=fortios.qcow2" -var "gui_disabled=false" fortigate-7.6.pkr.hcl
```

For FortiOS 7.2.0 and below

```bash
PACKER_LOG=1 packer build -var "version=7.2.0" -var "image_name=fortios.qcow2" -var "gui_disabled=false" fortigate-ssl-vrf.pkr.hcl
```

Or you can run Packer without debug

```bash
packer build -var "version=7.6.3" -var "image_name=fortios.qcow2" fortigate-7.6.pkr.hcl
```

For FortiOS 7.2.0 and below

```bash
packer build -var "version=7.2.0" -var "image_name=fortios.qcow2" fortigate-ssl-vrf.pkr.hcl
```

Move the Vagrant box to the libvirt directory

```bash
sudo mv ./builds/fortinet-fortigate-7.6.3.box /var/lib/libvirt/images
```

Copy the box metadata file to the libvirt directory

```bash
sudo cp ./src/fortigate.json /var/lib/libvirt/images
```

Substitute the VER placeholder string with the FortiOS version you're using.

```bash
vm_version="7.6.3"
sudo sed -i "s/\"version\": \"VER\"/\"version\": \"$vm_version\"/; s#\"url\": \"file:///var/lib/libvirt/images/fortinet-fortigate-VER.box\"#\"url\": \"file:///var/lib/libvirt/images/fortinet-fortigate-$vm_version.box\"#" /var/lib/libvirt/images/fortigate.json
```

Add the Vagrant box to the local inventory

```bash
vagrant box add --box-version 7.6.3 /var/lib/libvirt/images/fortigate.json
```

To register the VM, go back to the main working directory and run the VM

```bash
vagrant up fortigate-1
```

Wait, then connect to the VM via SSH.

```bash
vagrant ssh fortigate-1
```

There is a problem with newer versions of FortiGate that require an evaluation license to activate - they cannot accept the current configuration provided via Packer. When you try to register, you will get the error `Requesting FortiCare Trial license, proxy:(null)`. To fix this, reset the config by running `execute factoryreset` and confirm. You will lose the SSH connection, and after a few minutes you can go to `https://192.168.225.10` in your localhost browser, log in to FortiGate using `admin` / `admin` as credentials, and register your FortiGate. After reboot, disable any features, then you can either leave the VM running or shut it down for now.

You can use the same logic to build a FortiGate 7.2.0 box, but you will not be asked to register the VM - instead, you will have 15 days of trial access. Keep in mind that you need to uncomment and change the FortiGate version in `/vms/firewalls/fortigate/config.rb` if you want to test multiple versions.

```bash
# node.vm.box_version = "7.2.0"
```
