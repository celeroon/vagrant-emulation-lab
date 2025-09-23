# Setup Kali Linux

In this section, we will bring up a Kali Linux VM with RDP access via Guacamole.

Run the VM:

```bash
vagrant up kali-linux-1
```

Access the VM by name using `vagrant ssh` or via the management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

Next, define the variables below, replacing the IP addresses for `VM_MGMT_IP` and `LAB_IP`:

```bash
MGMT_IP="192.168.225.5"
```

Remember that Kali Linux is located in the **lab Internet network** (`100.66.0.0/29`):

```bash
LAB_IP="100.66.0.6"
```

Before editing the network settings, you can load Kali Linux via VNC and edit them in the GUI. Alternatively, you can follow the instructions below.

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
  netmask 255.255.255.248
  gateway 100.66.0.1
  dns-nameservers 8.8.8.8
  pre-up sleep 2
EOF
```

Restart the networking service:

```bash
sudo systemctl restart networking
```

Update the system:

```bash
sudo apt update
```

Install XRDP:

```bash
sudo apt install xrdp
```

Enable XRDP:

```bash
sudo systemctl enable xrdp
```

Start XRDP:

```bash
sudo systemctl restart xrdp
```

Finally, go to the [Guacamole setup section](/resources/docs/setup-guacamole.md) and add a new RDP connection for Kali Linux.
