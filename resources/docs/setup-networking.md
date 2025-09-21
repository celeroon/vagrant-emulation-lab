# Universal guide to setup VM networking on all Linux based VMs

Open the [topology](/resources/images/vagrant-lab-virtual-topology.svg) and define the variables below, replacing the IP address for `VM_MGMT_IP` and `LAB_IP`.

```bash
MGMT_IP="192.168.225.11"
```

```bash
LAB_IP="172.16.10.10"
```

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
  gateway 172.16.10.254
  dns-nameservers 8.8.8.8
  pre-up sleep 2
EOF
```

Restart networking service

```bash
sudo systemctl restart networking
```
