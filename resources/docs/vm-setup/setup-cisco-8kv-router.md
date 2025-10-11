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

Configure extended ACL for NAT (with NAT exempt for S2S connection)

```bash
ip access-list extended ACL-NAT-S2S
 10 deny ip 172.30.10.0 0.0.0.255 172.16.20.0 0.0.0.255
 20 deny ip 172.30.10.0 0.0.0.255 172.16.10.0 0.0.0.255
 30 permit ip 172.30.10.0 0.0.0.255 any
exit
```

Configure NAT

```bash
ip nat inside source list ACL-NAT-S2S interface GigabitEthernet2 overload
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

In this lab environment, I also want to configure Guestshell on the Cisco router to expose more applications that could be used in adversary emulation scenarios.

Enable IOX (IOX eXtensions) for container support in configuration mode

```bash
iox
```

Create ACL for NAT to access the Internet

```bash
ip access-list extended IOX_TO_INTERNET
  10 deny   ip 192.168.123.0 0.0.0.255 172.16.10.0 0.0.0.255
  20 deny   ip 192.168.123.0 0.0.0.255 172.16.20.0 0.0.0.255
  30 permit ip 192.168.123.0 0.0.0.255 any
exit
```

Configure NAT overload on Gi2 for IOX

```bash
ip nat inside source list IOX_TO_INTERNET interface GigabitEthernet2 overload
```

Create policy NAT guestshell to a LAN IP for remote networks. Create policy to match guestshell -> remote networks

```bash
ip access-list extended IOX_TO_HQ
 permit ip 192.168.123.0 0.0.0.255 172.16.10.0 0.0.0.255
 permit ip 192.168.123.0 0.0.0.255 172.16.20.0 0.0.0.255
exit
```

Single-IP pool to look like LAN host

```bash
ip nat pool IOX_AS_LAN 172.30.10.254 172.30.10.254 netmask 255.255.255.0
```

Route-map for selective NAT into the LAN IP

```bash
route-map RM-IOX-HQ permit 10
 match ip address IOX_TO_HQ
exit
```

Apply policy NAT (outside is Gi2; inside are Gi3 + virtualportgroup0)

```bash
ip nat inside source route-map RM-IOX-HQ pool IOX_AS_LAN
```

Enter virtual port group interface

```bash
interface virtualportgroup 0
```

Set IP address for virtual interface

```bash
ip address 192.168.123.1 255.255.255.0
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
guest-ipaddress 192.168.123.5 netmask 255.255.255.0
```

Exit app-hosting configuration

```bash
exit
```

Set default gateway for guest

```bash
app-default-gateway 192.168.123.1 guest-interface 0
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

To configure a policy-based IPsec VPN to the HQ FortiGate, run these commands on the branch router.

Enter configuration mode

```bash
configure terminal
```

Define IKEv2 proposal with chosen encryption, integrity, and DH group

```bash
crypto ikev2 proposal IKEv2-PROP
 encryption des
 integrity sha1
 group 2
exit
```

Create IKEv2 policy binding local address with proposal

```bash
crypto ikev2 policy PL-S2S
 !match address local 100.64.0.6
 proposal IKEv2-PROP
exit
```

Define keyring with remote peer and pre-shared key

```bash
crypto ikev2 keyring S2S_KEY
 peer FortiGate
 address 192.0.2.6
 pre-shared-key vagrant
 exit
exit
```

Define IKEv2 profile with authentication and keyring

```bash
crypto ikev2 profile IKEV2-PROF
 match identity remote address 192.0.2.6
 identity local address 100.64.0.6
 authentication remote pre-share
 authentication local pre-share
 keyring local S2S_KEY
exit
```

Define IPsec transform set for Phase 2 negotiation

```bash
crypto ipsec transform-set ESP-DES-SHA esp-des esp-sha-hmac
exit
```

Define ipsec profile

```bash
crypto ipsec profile IPSEC-PROF
 set transform-set ESP-DES-SHA
 set ikev2-profile IKEV2-PROF
exit
```

Access-list defining interesting traffic between local and remote subnets

```bash
ip access-list extended ACL-S2S
 10 permit ip 172.30.10.0 0.0.0.255 172.16.20.0 0.0.0.255
 20 permit ip 172.30.10.0 0.0.0.255 172.16.10.0 0.0.0.255
exit
```

Create crypto map with peer, profile, transform set, and ACL

```bash
crypto map CMAP-S2S 10 ipsec-isakmp
 set peer 192.0.2.6
 set pfs group2
 set security-association lifetime seconds 3600
 set ikev2-profile IKEV2-PROF
 set transform-set ESP-DES-SHA
 match address ACL-S2S
exit
```

Apply crypto map to interface

```bash
interface GigabitEthernet2
 crypto map CMAP-S2S
exit
```

Set up the timezone, for example CET. Set the default timezone to CET (UTC+1):

```bash
clock timezone CET 1
```

Configure summer time (CEST = CET+1)

```bash
clock summer-time CEST recurring last Sun Mar 2:00 last Sun Oct 3:00
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

Log failed interactive logins (SSH, console, VTY)

```bash
login on-failure log
```

Log failed interactive logins

```bash
login on-success log
```

Enable archive log config

```bash
archive
 log config
  logging enable
  notify syslog
  hidekeys
 exit
exit
```

Save configuration

```bash
end
wr
```
