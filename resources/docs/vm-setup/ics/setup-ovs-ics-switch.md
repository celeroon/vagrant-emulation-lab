# Setup ICS Open vSwitches

In this section, we will set up OVS switches in the ICS branch based on the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

Run VM

```bash
vagrant up ovs-ics-1
```

Access the VM by name using `vagrant ssh` or via the management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

```bash
vagrant ssh ovs-ics-1
```

Install the required package

```bash
sudo apt update
sudo apt install openvswitch-switch -y
```

Enable OVS service

```bash
sudo systemctl enable openvswitch-switch
sudo systemctl start openvswitch-switch
```

Configure the full networking using the code below:

```bash
cat <<'EOF' | sudo tee /etc/network/interfaces > /dev/null
# Loopback
auto lo
iface lo inet loopback

# Management interface eth0
auto eth0
iface eth0 inet static
    address 192.168.225.191
    netmask 255.255.255.0
    gateway 192.168.225.1
    dns-nameservers 8.8.8.8

# OVS Bridge
auto br0
iface br0 inet manual
    ovs_type OVSBridge
    ovs_ports eth1 eth2 eth3 eth4 eth5 eth6 eth7 eth8

# Uplink trunk eth1 to FortiGate (VLANs 90, 95)
auto eth1
iface eth1 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options trunks=90,95

# Access port ICS, DMZ
auto eth2
iface eth2 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=90

auto eth3
iface eth3 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=90

auto eth4
iface eth4 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=95

auto eth5
iface eth5 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=95

auto eth6
iface eth6 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=95

auto eth7
iface eth7 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=95

auto eth8
iface eth8 inet manual
    ovs_bridge br0
    ovs_type OVSPort
EOF
```

Restart networking service

```bash
sudo systemctl restart networking
```

Configure mirror port

```bash
sudo ovs-vsctl \
  -- --id=@eth1 get port eth1 \
  -- --id=@eth2 get port eth2 \
  -- --id=@eth3 get port eth3 \
  -- --id=@eth4 get port eth4 \
  -- --id=@eth5 get port eth5 \
  -- --id=@eth6 get port eth6 \
  -- --id=@eth7 get port eth7 \
  -- --id=@out get port eth8 \
  -- --id=@m create mirror name=mirror0 \
        select-src-port=@eth1,@eth2,@eth3,@eth4,@eth5,@eth6,@eth7 \
        select-dst-port=@eth1,@eth2,@eth3,@eth4,@eth5,@eth6,@eth7 \
        output-port=@out \
  -- set bridge br0 mirrors=@m
```
