# Setup Open vSwitches

In this section we will setup OVS switches in the HQ based on [topology](/resources/images/vagrant-lab-virtual-topology.svg). OVS supports a lot of advanced features that can be used later in this lab, such as mirorring traffic and NetFlow. Remember that you can replace box name in any of those switches if you want to test integration from diferent vendors. 

I want to leave here ovs-vsctl commands as an example for simple configuration. This commands will not be used in this setup, but rather as a reference. We will create persist configuration right away.

Bring up interfaces from eth1 to eth8

```
for i in {1..8}; do sudo ip link set eth$i up; done
```

Create the bridge

```
sudo ovs-vsctl add-br br0
```

Add eth1 interface as trunk with VLAN 10 and 20

```
sudo ovs-vsctl add-port br0 eth1 -- set port eth1 trunks=10,20
```

Assign interfaces from eth2 to eth4 to access ports in VLAN 20

```
sudo ovs-vsctl add-port br0 eth2 \
  -- set port eth2 tag=20
```

```
sudo ovs-vsctl add-port br0 eth3 \
  -- set port eth3 tag=20
```

```
sudo ovs-vsctl add-port br0 eth4 \
  -- set port eth4 tag=20
```

And another interfaces from eth5 to eth8 to VLAN 10

```
sudo ovs-vsctl add-port br0 eth5 \
  -- set port eth5 tag=10
```

```
sudo ovs-vsctl add-port br0 eth6 \
  -- set port eth6 tag=10
```

```
sudo ovs-vsctl add-port br0 eth7 \
  -- set port eth7 tag=10
```

```
sudo ovs-vsctl add-port br0 eth8 \
  -- set port eth8 tag=10
```

We can also create SVI interface with IP address

```
sudo ovs-vsctl add-port br0 vlan10 \
  -- set interface vlan10 type=internal \
  -- set port vlan10 tag=10
```

Bring it up interface: 

```
sudo ip addr add 172.16.10.253/24 dev vlan10
sudo ip link set vlan10 up
```

## Configure Core switch

Run VM

```bash
vagrant up ovs-core-1
```

Access VM by name using vagrant ssh or via management IP displayed on [topology](/resources/images/vagrant-lab-virtual-topology.svg)

```bash
vagrant ssh ovs-core-1
```

Install required package

```
sudo apt update
sudo apt install openvswitch-switch -y
```

Enable OVS service

```
sudo systemctl enable openvswitch-switch
sudo systemctl start openvswitch-switch
```

Configure full networking by code below

```bash
cat <<'EOF' | sudo tee /etc/network/interfaces > /dev/null
# Loopback
auto lo
iface lo inet loopback

# Management interface eth0
auto eth0
iface eth0 inet static
    address 192.168.225.11
    netmask 255.255.255.0

# OVS Bridge
auto br0
iface br0 inet manual
    ovs_type OVSBridge
    ovs_ports eth1 eth2 eth3 eth4 eth5 eth6 eth7 eth8 vlan10

# Uplink trunk eth1 to FortiGate (VLANs 10,20,30)
auto eth1
iface eth1 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options trunks=10,20,30

# Trunk to ovs-servers
auto eth2
iface eth2 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options trunks=10

# Trunk to ovs-users
auto eth3
iface eth3 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options trunks=10,20

# Trunk to ovs-dmz
auto eth4
iface eth4 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options trunks=10,30

# Reserved ports added to bridge
auto eth5
iface eth5 inet manual
    ovs_bridge br0
    ovs_type OVSPort

auto eth6
iface eth6 inet manual
    ovs_bridge br0
    ovs_type OVSPort

auto eth7
iface eth7 inet manual
    ovs_bridge br0
    ovs_type OVSPort

auto eth8
iface eth8 inet manual
    ovs_bridge br0
    ovs_type OVSPort

# SVI for VLAN 10
auto vlan10
iface vlan10 inet static
    ovs_bridge br0
    ovs_type OVSIntPort
    ovs_options tag=10
    address 172.16.10.253
    netmask 255.255.255.0
EOF
```

Restart networking service

```bash
sudo systemctl restart networking
```

## Configure Servers switch

Run VM

```bash
vagrant up ovs-servers-1
```

Access VM by name using vagrant ssh or via management IP displayed on [topology](/resources/images/vagrant-lab-virtual-topology.svg)

```bash
vagrant ssh ovs-servers-1
```

Install required package

```
sudo apt update
sudo apt install openvswitch-switch -y
```

Enable OVS service

```
sudo systemctl enable openvswitch-switch
sudo systemctl start openvswitch-switch
```

Configure full networking by code below

```bash
cat <<'EOF' | sudo tee /etc/network/interfaces > /dev/null
# Loopback
auto lo
iface lo inet loopback

# Management interface eth0
auto eth0
iface eth0 inet static
    address 192.168.225.12
    netmask 255.255.255.0

# OVS bridge
auto br0
iface br0 inet manual
    ovs_type OVSBridge
    ovs_ports eth1 vlan10 \
              eth2 eth3 eth4 eth5 eth6 eth7 eth8 eth9 eth10 \
              eth11 eth12 eth13 eth14 eth15 eth16 eth17 eth18 eth19 eth20 \
              eth21 eth22 eth23 eth24 eth25 eth26 eth27 eth28 eth29 eth30 \
              eth31 eth32

# Uplink trunk on eth1 (only VLAN 10 allowed)
auto eth1
iface eth1 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options trunks=10

# Access ports eth2–eth30 in VLAN 10
auto eth2
iface eth2 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth3
iface eth3 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth4
iface eth4 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth5
iface eth5 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth6
iface eth6 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth7
iface eth7 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth8
iface eth8 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth9
iface eth9 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth10
iface eth10 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth11
iface eth11 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth12
iface eth12 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth13
iface eth13 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth14
iface eth14 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth15
iface eth15 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth16
iface eth16 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth17
iface eth17 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth18
iface eth18 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth19
iface eth19 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth20
iface eth20 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth21
iface eth21 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth22
iface eth22 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth23
iface eth23 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth24
iface eth24 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth25
iface eth25 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth26
iface eth26 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth27
iface eth27 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth28
iface eth28 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth29
iface eth29 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10
auto eth30
iface eth30 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=10

# Reserved ports (on bridge, no tagging)
auto eth31
iface eth31 inet manual
    ovs_bridge br0
    ovs_type OVSPort

auto eth32
iface eth32 inet manual
    ovs_bridge br0
    ovs_type OVSPort

# SVI for VLAN 10
auto vlan10
iface vlan10 inet static
    ovs_bridge br0
    ovs_type OVSIntPort
    ovs_options tag=10
    address 172.16.10.252
    netmask 255.255.255.0
EOF
```

Restart networking service

```bash
sudo systemctl restart networking
```

## Configure Users switch

Run VM

```bash
vagrant up ovs-users-1
```

Access VM by name using vagrant ssh or via management IP displayed on [topology](/resources/images/vagrant-lab-virtual-topology.svg)

```bash
vagrant ssh ovs-users-1
```

Install required package

```
sudo apt update
sudo apt install openvswitch-switch -y
```

Enable OVS service

```
sudo systemctl enable openvswitch-switch
sudo systemctl start openvswitch-switch
```

Configure full networking by code below

```bash
cat <<'EOF' | sudo tee /etc/network/interfaces > /dev/null
# Loopback
auto lo
iface lo inet loopback

# Management interface eth0
auto eth0
iface eth0 inet static
    address 192.168.225.13
    netmask 255.255.255.0

# OVS bridge
auto br0
iface br0 inet manual
    ovs_type OVSBridge
    ovs_ports eth1 vlan10 \
              eth2 eth3 eth4 eth5 eth6 eth7 eth8 eth9 eth10 \
              eth11 eth12 eth13 eth14 eth15 eth16 eth17 eth18 eth19 eth20 \
              eth21 eth22 eth23 eth24 eth25 eth26 eth27 eth28 eth29 eth30 \
              eth31 eth32

# Uplink trunk on eth1 (only VLAN 10 allowed)
auto eth1
iface eth1 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options trunks=10,20

# Access ports eth2–eth30 in VLAN 10
auto eth2
iface eth2 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth3
iface eth3 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth4
iface eth4 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth5
iface eth5 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth6
iface eth6 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth7
iface eth7 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth8
iface eth8 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth9
iface eth9 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth10
iface eth10 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth11
iface eth11 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth12
iface eth12 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth13
iface eth13 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth14
iface eth14 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth15
iface eth15 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth16
iface eth16 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth17
iface eth17 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth18
iface eth18 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth19
iface eth19 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth20
iface eth20 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth21
iface eth21 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth22
iface eth22 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth23
iface eth23 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth24
iface eth24 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth25
iface eth25 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth26
iface eth26 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth27
iface eth27 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth28
iface eth28 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth29
iface eth29 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20
auto eth30
iface eth30 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=20

# Reserved ports (on bridge, no tagging)
auto eth31
iface eth31 inet manual
    ovs_bridge br0
    ovs_type OVSPort

auto eth32
iface eth32 inet manual
    ovs_bridge br0
    ovs_type OVSPort

# SVI for VLAN 10
auto vlan10
iface vlan10 inet static
    ovs_bridge br0
    ovs_type OVSIntPort
    ovs_options tag=10
    address 172.16.10.251
    netmask 255.255.255.0
EOF
```

Restart networking service

```bash
sudo systemctl restart networking
```

## Configure DMZ switch

Run VM

```bash
vagrant up ovs-dmz-1
```

Access VM by name using vagrant ssh or via management IP displayed on [topology](/resources/images/vagrant-lab-virtual-topology.svg)

```bash
vagrant ssh ovs-dmz-1
```

Install required package

```
sudo apt update
sudo apt install openvswitch-switch -y
```

Enable OVS service

```
sudo systemctl enable openvswitch-switch
sudo systemctl start openvswitch-switch
```

Configure full networking by code below

```bash
cat <<'EOF' | sudo tee /etc/network/interfaces > /dev/null
# Loopback
auto lo
iface lo inet loopback

# Management interface eth0
auto eth0
iface eth0 inet static
    address 192.168.225.14
    netmask 255.255.255.0

# OVS bridge
auto br0
iface br0 inet manual
    ovs_type OVSBridge
    ovs_ports eth1 vlan10 \
              eth2 eth3 eth4 eth5 eth6 eth7 eth8 eth9 eth10 \
              eth11 eth12 eth13 eth14 eth15 eth16 eth17 eth18 eth19 eth20 \
              eth21 eth22 eth23 eth24 eth25 eth26 eth27 eth28 eth29 eth30 \
              eth31 eth32

# Uplink trunk on eth1 (only VLAN 10 allowed)
auto eth1
iface eth1 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options trunks=10,30

# Access ports eth2–eth30 in VLAN 10
auto eth2
iface eth2 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth3
iface eth3 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth4
iface eth4 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth5
iface eth5 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth6
iface eth6 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth7
iface eth7 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth8
iface eth8 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth9
iface eth9 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth10
iface eth10 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth11
iface eth11 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth12
iface eth12 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth13
iface eth13 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth14
iface eth14 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth15
iface eth15 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth16
iface eth16 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth17
iface eth17 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth18
iface eth18 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth19
iface eth19 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth20
iface eth20 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth21
iface eth21 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth22
iface eth22 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth23
iface eth23 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth24
iface eth24 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth25
iface eth25 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth26
iface eth26 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth27
iface eth27 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth28
iface eth28 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth29
iface eth29 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30
auto eth30
iface eth30 inet manual
    ovs_bridge br0
    ovs_type OVSPort
    ovs_options tag=30

# Reserved ports (on bridge, no tagging)
auto eth31
iface eth31 inet manual
    ovs_bridge br0
    ovs_type OVSPort

auto eth32
iface eth32 inet manual
    ovs_bridge br0
    ovs_type OVSPort

# SVI for VLAN 10
auto vlan10
iface vlan10 inet static
    ovs_bridge br0
    ovs_type OVSIntPort
    ovs_options tag=10
    address 172.16.10.250
    netmask 255.255.255.0
EOF
```

Restart networking service

```bash
sudo systemctl restart networking
```