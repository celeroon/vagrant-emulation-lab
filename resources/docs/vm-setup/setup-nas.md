# Setup NAS

In this section, we will deploy **OpenMediaVault (OMV7)** as a NAS solution for this lab. Using Packer, you can build your own box and [replace the configuration file](/vms/linux/nas/config.rb) to use your custom box name.

You can also explore other projects such as **TrueNAS**.

As another alternative, if you have Synology hardware, you can install **VirtualDSM**. Read more in this [GitHub repo](https://github.com/vdsm/virtual-dsm).

Run the VM:

```bash
vagrant up nas-1
```

Access the VM by name using `vagrant ssh` or via the management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

Next, define the variables below, replacing the IP address for `VM_MGMT_IP` and `LAB_IP`:

```bash
MGMT_IP="192.168.225.49"
```

Remember that the NAS is located in the **users network** (`172.16.20.0/24`):

```bash
LAB_IP="172.16.20.100"
```

Configure the network:

```bash
cat <<EOF | sudo tee /etc/network/interfaces > /dev/null
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address $MGMT_IP
  netmask 255.255.255.0
  pre-up sleep 2

auto eth1
iface eth1 inet static
  address $LAB_IP
  netmask 255.255.255.0
  gateway 172.16.20.254
  dns-nameservers 8.8.8.8
  pre-up sleep 2
EOF
```

Restart the networking service:

```bash
sudo systemctl restart networking
```

Run the OMV 7 installation script:

```bash
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
```

After installation is finished, you will be able to access `http://172.16.20.100` from the Windows VM once it is deployed.
