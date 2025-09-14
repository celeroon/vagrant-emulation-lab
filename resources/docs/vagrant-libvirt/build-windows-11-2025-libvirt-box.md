## Build Windows 11/2025 box

In this lab you can use Windows 10 Vagrant boxes from Vagrant cloud, but if you want Windows 11 or Windows Server 2025 you need to build them.

Clone project

```bash
git clone https://github.com/rgl/windows-vagrant.git
cd windows-vagrant
```

Setup drivers

```bash
make drivers
```

> [!IMPORTANT]  
> You can add more CPU (cpus/cores), RAM (memory), and increase the SSH timeout in the *.pkr.hcl files.
> Box building can take up to a few hours!

Build Windows 11 Vagrant (libvirt) box
```bash
make build-windows-11-24h2-libvirt
```

Build Windows Server 2025 Vagrant (libvirt) box
```bash
make build-windows-2025-libvirt
```

Add the Windows 11 Vagrant box 

```bash
vagrant box add --name windows-11-24h2-amd64 \
  --provider=libvirt \
  windows-11-24h2-amd64-libvirt.box
```

Add the Windows 2025 Vagrant box 

```bash
vagrant box add --name windows-2025-amd64 \
  --provider=libvirt \
  windows-2025-amd64-libvirt.box
```

When you run the build process, after the image is downloaded you will see QEMU start the VM. When the message appears that it is waiting for an SSH connection, you will also see a VNC port opened. You can use Remote Viewer to watch the Windows installation process by connecting to `vnc://localhost:59xx`.
