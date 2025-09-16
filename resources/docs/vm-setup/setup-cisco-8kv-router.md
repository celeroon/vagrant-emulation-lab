# Setup Cisco Catalyst 8kv router

Run VM

```bash
vagrant up branch-router-1
```

Access Cisco router

```bash
vagrant ssh branch-router-1
```

(or) Using nomal SSH (password: `vagrant`)

```bash
ssh vagrant@192.168.225.8
```

Enter configuration mode

```bash
conf t
```

Change hostname:

```bash
hostname branch-router-1
```

Configure Internet-facing interface

```bash
interface GigabitEthernet2
no shutdown
description *** Internet Access to isp-router-1 ***
ip address 100.64.0.6 255.255.255.248
ip nat outside
exit
```

Configure internal interface

```bash
interface GigabitEthernet3
description *** To LAN switch ***
ip address 172.30.10.254 255.255.255.0
ip nat inside
no shutdown
exit
```

Configure default route

```bash
ip route 0.0.0.0 0.0.0.0 GigabitEthernet2 100.64.0.1
```

Configure extended ACL for NAT

```bash
ip access-list extended NAT_ACL
permit ip 172.30.10.0 0.0.0.255 any
exit
```

Configure NAT

```bash
ip nat inside source list NAT_ACL interface GigabitEthernet2 overload
```

To configure DHCP server first you need to exclude router address from DHCP:

```bash
ip dhcp excluded-address 172.30.10.254
```

Create a DHCP pool

```bash
ip dhcp pool LAN_POOL
network 172.30.10.0 255.255.255.0
default-router 172.30.10.254
dns-server 8.8.8.8
exit
```

Enable syslog logging

```bash
logging on
```

Add timestamp (date + milliseconds) to each log message

```bash
service timestamps log datetime msec
```

Define remote syslog server (ELK) and custom UDP port

```bash
logging host 172.16.10.5 transport udp port 9010
```

Send all syslog levels (0 = emergencies, 7 = debugging)

```bash
logging trap debugging
```

Use this interface’s IP as the source of syslog messages

```bash
logging source-interface GigabitEthernet3
```

Set syslog facility to local7

```bash
logging facility local7
```

In this lab environment, I also want to configure Guestshell on the Cisco router to expose more applications that could be used in adversary emulation scenarios.

Enable IOX (IOX eXtensions) for container support

```bash
iox
```

Create standard ACL for NAT translation

```bash
ip access-list standard IOX_NAT
permit 192.168.100.0 0.0.0.255
exit
```

Configure NAT overload on Gi2

```bash
ip nat inside source list IOX_NAT interface GigabitEthernet2 overload
```

Enter virtual port group interface

```bash
interface virtualportgroup 0
```

Set IP address for virtual interface

```bash
ip address 192.168.100.1 255.255.255.0
```

Configure as NAT inside interface

```bash
ip nat inside
```

Exit interface configuration

```bash
exit
```

Configure guestshell application hosting

```bash
app-hosting appid guestshell
```

Set virtual NIC gateway

```bash
app-vnic gateway0 virtualportgroup 0 guest-interface 0
```

Set guest IP address

```bash
guest-ipaddress 192.168.100.5 netmask 255.255.255.0
```

Exit app-hosting configuration

```bash
exit
```

Set default gateway for guest

```bash
app-default-gateway 192.168.100.1 guest-interface 0
```

Set DNS server for guest

```bash
name-server0 8.8.8.8
```

Exit configuration mode

```bash
end
```

Enable guestshell functionality

```bash
guestshell enable
```

Access shell

```bash
guestshell
```

Save configuration

```bash
end
wr
```
