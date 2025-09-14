# Setup branch host

For testing purposes in the branch, a Debian 11 Vagrant box will be deployed to verify connectivity.

Run test VM:

```bash
vagrant up branch-host-1
```

Access test VM

```bash
vagrant ssh branch-host-1
```

(or) Using normal SSH

```bash
ssh vagrant@192.168.225.29 -i ~/.vagrant.d/insecure_private_key
```

Configure interfaces in `/etc/network/interfaces`

```bash
cat <<EOF | sudo tee /etc/network/interfaces > /dev/null
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address 192.168.225.29
  netmask 255.255.255.0
  pre-up sleep 2

auto eth1
iface eth1 inet dhcp
  pre-up sleep 2
EOF
```

Restart networking service

```bash
sudo systemctl restart networking
```

Verify connectivity using ping or traceroute to publicly available services to ensure that traffic is routed through the branch router based on the [topology](/resources/images/vagrant-lab-virtual-topology.svg).
