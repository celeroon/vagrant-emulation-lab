# Setup CAPEv2 node

In this section, we will create a CAPEv2 instance in the lab. This setup will probably be manual only, as it is difficult to configure with automation scripts, especially when disabling all unnecessary services on Windows. The official documentation recommends using Windows 10 21H2, but we will use a Windows 10 box from Vagrant Cloud (22H2). This setup is for lab use only; to run it in production, you need to properly configure the VM, for example, to avoid virtualization detection. The following tools may be useful:

* [https://github.com/a0rtega/pafish](https://github.com/a0rtega/pafish)
* [https://github.com/ayoubfaouzi/al-khaser](https://github.com/ayoubfaouzi/al-khaser)

You can find the official recommendations in the repository:
[Installation recommendations and scripts for optimal performance](https://github.com/kevoreilly/CAPEv2?tab=readme-ov-file#installation-recommendations-and-scripts-for-optimal-performance)

I followed the instructions described in Rizqi Setyo Kusprihantanto’s blog posts:

* [https://osintteam.blog/building-capev2-automated-malware-analysis-sandbox-part-1-da2a6ff69cdb](https://osintteam.blog/building-capev2-automated-malware-analysis-sandbox-part-1-da2a6ff69cdb)
* [https://infosecwriteups.com/building-capev2-automated-malware-analysis-sandbox-part-2-0c47e4b5cbcd](https://infosecwriteups.com/building-capev2-automated-malware-analysis-sandbox-part-2-0c47e4b5cbcd)
* [https://osintteam.blog/building-capev2-automated-malware-analysis-sandbox-part-3-d5535a0ab6f6](https://osintteam.blog/building-capev2-automated-malware-analysis-sandbox-part-3-d5535a0ab6f6)

> [!IMPORTANT]  
> Before running the VM, make sure to edit the [configuration](/vms/linux/capev2/config.rb) file with the appropriate CPU and RAM amounts based on your environment.

Run base VM

```bash
vagrant up capev2-1
```

Access the VM by name using `vagrant ssh` or via the management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

Configure networking

```bash
sudo tee /etc/netplan/01-interfaces.yaml > /dev/null <<'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    ens7:
      addresses: [192.168.225.104/24]
      dhcp4: false
      dhcp6: false
    ens8:
      addresses: [172.16.10.4/24]
      routes:
        - to: 0.0.0.0/0
          via: 172.16.10.254
      nameservers:
        addresses: [8.8.8.8]
      dhcp4: false
      dhcp6: false
EOF
```

Apply changes

```bash
sudo netplan apply
```

Update and install the required tools:

```bash
sudo apt update && sudo apt upgrade -y
```

<!-- ```bash
sudo apt install git acpica-tools libxml2 libxml2-dev libxslt1-dev python3-libxml2 libgtk-vnc-2.0-dev gir1.2-gtk-vnc-2.0 gir1.2-gtksource-4 libgtksourceview-4-0 libgtksourceview-4-common python3-gi-cairo gir1.2-vte-2.90 libosinfo-1.0 python3-libvirt python3-requests graphviz graphviz-dev libvirt-dev parted -y
``` -->

```bash
sudo apt install git -y
```

Add attached `/dev/vdb` disk to existing LVM:

- Check already created LVM (get a volume name)

```bash
sudo pvs
```

- Create a physical volume on the new disk

```bash
sudo pvcreate /dev/vdb
```

- Verify

```bash
sudo pvs
```

- Extend your volume group to include the new disk

```bash
sudo vgextend ubuntu-vg /dev/vdb
```

- Check 

```bash
sudo vgs
```

- Extend the logical volume (root filesystem)

```bash
sudo lvextend -r -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
```

Confirm the resizing

```bash
df -h && sudo lvs
```

Clone the project repository

```bash
git clone https://github.com/kevoreilly/CAPEv2.git "$HOME/CAPEv2"
```

You can use the `acpidump` tool to get the DSDT code, but I will use the same one as in the tutorial for Dell Inspiron 5566 (https://github.com/linuxhw/ACPI).

```bash
sed -i 's/<WOOT>/CBX3/g' $HOME/CAPEv2/installer/kvm-qemu.sh
```

Run KVM installer

```bash
chmod a+x $HOME/CAPEv2/installer/kvm-qemu.sh
```

```bash
sudo $HOME/CAPEv2/installer/kvm-qemu.sh all cape 2>&1 | tee ./$HOME/CAPEv2/installer/kvm-qemu.log
```

```bash
sudo $HOME/CAPEv2/installer/kvm-qemu.sh virtmanager cape 2>&1 | tee $HOME/CAPEv2/installer/kvm-qemu-virtmanager.log
```

Reboot VM

```bash
sudo reboot now
```

Edit the CAPEv2 installation script with the created network interface, network, and database password (you can change it).

```bash
sed -i \
  -e 's/^NETWORK_IFACE=.*/NETWORK_IFACE=virbr0/' \
  -e 's/^\(IFACE_IP=\).*/\1"192.168.122.1"/' \
  -e 's/^PASSWD=.*/PASSWD="vagrant"/' \
  $HOME/CAPEv2/installer/cape2.sh
```

Run installation script

```bash
chmod a+x $HOME/CAPEv2/installer/cape2.sh
```

```bash
sudo $HOME/CAPEv2/installer/cape2.sh base 2>&1 | tee $HOME/CAPEv2/installer/cape2-base.log
```

Reboot VM

```bash
sudo reboot now
```

Install additional features

```bash
poetry --directory /opt/CAPEv2 run pip3 install -r extra/optional_dependencies.txt
```

```bash
poetry --directory /opt/CAPEv2 run pip3 install chepy
```

```bash
sudo apt install graphviz graphviz-dev -y
```

Add DHCP reservation for Windows 10 VM

```bash
sudo EDITOR=nano virsh net-edit default
```

Add line right after `range` in `dhcp` section

```bash
<host mac='52:54:00:aa:bb:cc' ip='192.168.122.250'/>
```

<div align="center">
    <img alt="DHCP reservation" src="/resources/images/capev2/dhcp-reservation.png" width="100%">
</div>

Restart the network:

```bash
sudo virsh net-destroy default
```

```bash
sudo virsh net-start default
```

You should now see your static DHCP mapping

```bash
sudo virsh net-dumpxml default | grep host
```

Make sure the host can forward packets:

```bash
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo sysctl -w net.ipv4.ip_forward=1
```

To make it permanent (optional):

```bash
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p
```

Add DNAT rules (simple port forwarding)

- Do DNAT for incoming traffic from the external interface (ens7) and forward it to the Windows VM (192.168.122.250)

```bash
sudo iptables -t nat -I PREROUTING 1 -i ens7 -p tcp --dport 5986 -j DNAT --to-destination 192.168.122.250:5986
```

```bash
sudo iptables -t nat -I PREROUTING 1 -i ens7 -p tcp --dport 3389 -j DNAT --to-destination 192.168.122.250:3389
```

- Allow forwarding in both directions

```bash
sudo iptables -I FORWARD 1 -i ens7  -o virbr0 -p tcp -d 192.168.122.250 --dport 5986 -j ACCEPT
```

```bash
sudo iptables -I FORWARD 1 -i ens7  -o virbr0 -p tcp -d 192.168.122.250 --dport 3389 -j ACCEPT
```

```bash
sudo iptables -I FORWARD 1 -i virbr0 -o ens7  -p tcp -s 192.168.122.250 --sport 5986 -m state --state ESTABLISHED,RELATED -j ACCEPT
```

```bash
sudo iptables -I FORWARD 1 -i virbr0 -o ens7  -p tcp -s 192.168.122.250 --sport 3389 -m state --state ESTABLISHED,RELATED -j ACCEPT
```

(Optional) Make rules persistent

```bash
sudo apt install iptables-persistent -y
sudo netfilter-persistent save
```

Move back to the main host project directory and run the Windows 10 sandbox VM. If you changed the topology management addressing, make sure to edit the [Vagrantfile](/vms/linux/capev2/windows-sandobx/Vagrantfile)

```bash
VAGRANT_CWD=$HOME/vagrant-manual-lab/vms/linux/capev2/windows-sandobx/ vagrant up
```

It may take a while for Windows 10 to start up. While waiting for Vagrant to finish the job, you can already access the VM via VNC. Open **Remote Viewer** and provide the protocol, IP address, and port to connect: `vnc://192.168.225.104:5999`.

Instead of VNC, you can use RDP based on the forwarded ports we configured. Use the `remmina` or `freerdp2-x11` tool to access the Windows VM. Use the Ubuntu VM’s IP address, as the ports are forwarded:

```bash
xfreerdp /u:Administrator /v:192.168.225.104 /monitors:0 /multimon /port:3389
```

Based on the information provided on original [blog post](https://infosecwriteups.com/building-capev2-automated-malware-analysis-sandbox-part-2-0c47e4b5cbcd) - you need to disable Windows Defender and two repositories are provided:

* [ionuttbara](https://github.com/ionuttbara/windows-defender-remover)
* [es3n1n](https://github.com/es3n1n/no-defender)

I will test first one, the instructions are provided in the repo, where packed script is available on project releases, you can just run `.exe.`.


