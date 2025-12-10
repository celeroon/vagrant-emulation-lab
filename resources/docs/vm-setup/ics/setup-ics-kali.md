# Setup ICS Kali Linux

Run VM

```bash
vagrant up ics-kali-1
```

Access the VM by name using `vagrant ssh` or via the management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

Configure networking

```bash
sudo tee /etc/network/interfaces <<EOF
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address 192.168.225.195
  netmask 255.255.255.0
  gateway 192.168.225.1
  dns-nameservers 8.8.8.8

auto eth1
iface eth1 inet static
  address 172.16.95.11
  netmask 255.255.255.0
  post-up ip route add 172.16.90.0/24 via 172.16.95.254
  pre-down ip route del 172.16.90.0/24 via 172.16.95.254
EOF
```

Restart networking

```bash
sudo systemctl restart networking 
```

Now let's go to the simple scenario. You can experiment with a scenario that is described by Fortiphyd Logic Inc (https://youtu.be/rak6wODfzd0?si=xzDgmUsxeY9kTaM7). If you are interested in building a more complex lab - visit their GitHub page of the project GRFICSv3 (https://github.com/Fortiphyd/GRFICSv3). There it is shown how to use metasploit for this. 
For my setup I want to use just a simple tool described below. First, you can capture packets on the ICS network and use Wireshark to analyze them by expanding the modbus section to see data values that have been sent. There are a lot of packets that read coils (or registers) represented in a binary format True or False. Here you can see bits 0, 1, 2 and 3 with values of 0, 1, 1, 0. In most packets you can observe that bit 2 stays at 1 and bit 3 stays at 0

<div align="center">
    <img alt="ICS wireshark PLC coils" src="/resources/images/ics/ics-wireshark-coils.png" width="100%">
</div>

Those bits are represented in the monitoring section of OpenPLC

<div align="center">
    <img alt="ICS wireshark PLC coils" src="/resources/images/ics/ics-openplc-monitoring.png" width="100%">
</div>

Those bits indicate the Gas Storage Tank which is typically disabled in most parts of the automatic lab processing when High Pressure Tank goes to a high position (yellow).

<div align="center">
    <img alt="ICS simulation" src="/resources/images/ics/ics-simulation-1.png" width="100%">
</div>

So let's use the `modbus-cli` tool (I used a tutorial described here https://zerontek.com/zt/2025/07/20/using-modbus-cli-to-read-and-write-modbus-coils-in-labshock/) and first install it:

```bash
sudo apt install ruby-full
```

```bash
gem install modbus-cli
```

```bash
echo 'export PATH="$HOME/.local/share/gem/ruby/3.3.0/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

So, first using the `modbus-cli` tool on Kali, let's read coil values. From Wireshark analysis (and OpenPLC) we know that there are only 4 bits

<div align="center">
    <img alt="ICS simulation" src="/resources/images/ics/ics-kali-1.png" width="100%">
</div>

Since modbus-cli uses zero-based addressing - compressor is bit 2 and Gas Storage Tank is bit 4

In the HMI (FUXA) switch to the manual mode and use `modbus-cli` to change registers to HIGH states, and now HMI shows all tanks as full after a few minutes

<div align="center">
    <img alt="ICS simulation" src="/resources/images/ics/ics-kali-2.png" width="100%">
</div>

Now you can monitor traffic on the Malcolm node. There is a modbus section and you can for example build rules based on a server and a client combined with modbus read and writes and define who can communicate and create triggers (rules) based on this data.

<div align="center">
    <img alt="ICS simulation" src="/resources/images/ics/ics-malcolm-1.png" width="100%">
</div>

Also, I want to show another example with FortiGate firewall with application control on a policy. In the security profiles you can block even all industrial category or a specific one.

<div align="center">
    <img alt="ICS simulation" src="/resources/images/ics/ics-fortigate-1.png" width="100%">
</div>

For example with this application control profile you can block access to industrial protocols but allow another. You can also exclude HMI from this policy.

<div align="center">
    <img alt="ICS simulation" src="/resources/images/ics/ics-fortigate-2.png" width="100%">
</div>

Just for demo purposes, I enable for all communication from DMZ to ICS networks and see that the connection will be blocked.

<div align="center">
    <img alt="ICS simulation" src="/resources/images/ics/ics-fortigate-3.png" width="100%">
</div>

Also you will see that HMI will freeze, heartbeat will be red only and a message about that connection to PLC is lost.

<div align="center">
    <img alt="ICS simulation" src="/resources/images/ics/ics-hmi-1.png" width="100%">
</div>

Also, I want to show another integration of FortiGate with Elasticsearch via Logstash custom [FortiDragon pipelines](https://github.com/enotspe/fortinet-2-elasticsearch) by sending syslog to the ELK node. Using the same pipelines, Elastic rules can be created to trigger about events related to industrial systems.

<div align="center">
    <img alt="ICS simulation" src="/resources/images/ics/ics-elk-1.png" width="100%">
</div>

<div align="center">
    <img alt="ICS simulation" src="/resources/images/ics/ics-elk-2.png" width="100%">
</div>

<div align="center">
    <img alt="ICS simulation" src="/resources/images/ics/ics-elk-3.png" width="100%">
</div>
