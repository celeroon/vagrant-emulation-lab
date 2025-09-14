# Build Cisco Catalyst Vagrant (libvirt) box

To get the image, a service contract is required. I will deploy version 17.10.01a of Cisco Cat8kv. In this lab, it will function as a branch router. This is an optional deployment, you can omit it.

In the main working directory, clone and enter the repository.

```bash
git clone https://github.com/celeroon/cisco-catalyst-8kv-vagrant-libvirt
cd cisco-catalyst-8kv-vagrant-libvirt
```

Change the image name to `cisco-catalyst-8kv.qcow2` and move it to `/var/lib/libvirt/images/`

```bash
sudo mv ./cisco-catalyst-8kv.qcow2 /var/lib/libvirt/images/
```

Set ownership and permissions

```bash
sudo chown libvirt-qemu:kvm /var/lib/libvirt/images/cisco-catalyst-8kv.qcow2
sudo chmod 640 /var/lib/libvirt/images/cisco-catalyst-8kv.qcow2
```

Run Packer to build the box. I recommend enabling debug mode. This will not open QEMU window, because this provisioning uses telnet, so everything will appear as clear text in the terminal

```bash
PACKER_LOG=1 packer build -var "version=17.10.01a" -var "image_name=cisco-catalyst-8kv.qcow2" cisco-cat-8kv.pkr.hcl
```

Move the created Vagrant Box to the `/var/lib/libvirt/images` directory:

```bash
sudo mv ./builds/cisco-catalyst-8kv*.box /var/lib/libvirt/images
```

Copy the metadata file to the `/var/lib/libvirt/images` directory:

```bash
sudo cp ./src/cisco-catalyst-8kv.json /var/lib/libvirt/images
```

Update the Vagrant Box metadata file with the correct path and version (make sure to change version):

```bash
vm_version="17.10.01a"
sudo sed -i "s/\"version\": \"VER\"/\"version\": \"$vm_version\"/; s#\"url\": \"file:///var/lib/libvirt/images/cisco-catalyst-8kv-VER.box\"#\"url\": \"file:///var/lib/libvirt/images/cisco-catalyst-8kv-$vm_version.box\"#" /var/lib/libvirt/images/cisco-catalyst-8kv.json
```

Add the Cisco Catalyst 8kv Vagrant Box to the inventory (make sure to change version):

```bash
vagrant box add --box-version 17.10.01a /var/lib/libvirt/images/cisco-catalyst-8kv.json
```
