# Setup VyOS router

Bring VM up:

```bash
vagrant up vyos-isp-router-1
```

Access the VyOS router:

```bash
vagrant ssh vyos-isp-router-1
```

(or) Using normal SSH (vyos/vyos):

```bash
ssh vyos@192.168.225.9 -i ~/.vagrant.d/insecure_private_key
```

You can also access the VM via VNC through the Cockpit GUI by launching Remote Viewer. 

<div align="center">
    <img alt="VyOS VNC Access" src="/resources/images/vyos/vyos-vnc.png" width="100%">
</div>

Enter configuration mode

```bash
configure
```

Change hostname

```bash
set system host-name ISP-ROUTER-1
```

Configure Internet facing interface (eth1)

```bash
set interfaces ethernet eth1 address dhcp
set interfaces ethernet eth1 description '***Internet Access***'
```

Configure HQ Firewall interface (eth2)

```bash
set interfaces ethernet eth2 address 192.0.2.1/29
set interfaces ethernet eth2 description '***To HQ Firewall***'
```

Configure Email Server interface (eth3)

```bash
set interfaces ethernet eth3 address 203.0.113.1/29
set interfaces ethernet eth3 description '***To Email Server***'
```

Configure C2 Server interface (eth4)

```bash
set interfaces ethernet eth4 address 198.51.100.1/29
set interfaces ethernet eth4 description '***To C2 Server***'
```

Configure Payload Server interface (eth5)

```bash
set interfaces ethernet eth5 address 100.65.0.1/29
set interfaces ethernet eth5 description '***To Payload Server***'
```

Configure Kali interface (eth6)

```bash
set interfaces ethernet eth6 address 100.66.0.1/29
set interfaces ethernet eth6 description '***To Kali***'
```

Configure Branch-1 interface (eth7)

```bash
set interfaces ethernet eth7 address 100.64.0.1/29
set interfaces ethernet eth7 description '***To Branch-1***'
```

Configure ICS-Branch interface (eth8)

```bash
set interfaces ethernet eth8 address 100.67.0.1/29
set interfaces ethernet eth8 description '***To ICS-Branch***'
```

Configure default route via upstream gateway (lab virbr10 interface)

```bash
set protocols static route 0.0.0.0/0 next-hop 10.1.1.1
```

Configre NAT rules:

* rule 100 to NAT HQ Firewall subnet traffic

```bash
set nat source rule 100 description 'NAT HQ-Firewall'
```

```bash
set nat source rule 100 source address 192.0.2.0/29
```

```bash
set nat source rule 100 outbound-interface name eth1
```

```bash
set nat source rule 100 translation address masquerade
```

* rule 101 to NAT Email Server subnet traffic

```bash
set nat source rule 101 description 'NAT Email Server'
```

```bash
set nat source rule 101 source address 203.0.113.0/29
```

```bash
set nat source rule 101 outbound-interface name eth1
```

```bash
set nat source rule 101 translation address masquerade
```

* rule 102 to NAT C2 subnet traffic

```bash
set nat source rule 102 description 'NAT C2'
```

```bash
set nat source rule 102 source address 198.51.100.0/29
```

```bash
set nat source rule 102 outbound-interface name eth1
```

```bash
set nat source rule 102 translation address masquerade
```

* rule 103 to NAT HQ Payload Server subnet traffic

```bash
set nat source rule 103 description 'NAT Payload Server'
```

```bash
set nat source rule 103 source address 100.65.0.0/29
```

```bash
set nat source rule 103 outbound-interface name eth1
```

```bash
set nat source rule 103 translation address masquerade
```

* rule 104 to NAT Kali subnet traffic

```bash
set nat source rule 104 description 'NAT Kali'
```

```bash
set nat source rule 104 source address 100.66.0.0/29
```

```bash
set nat source rule 104 outbound-interface name eth1
```

```bash
set nat source rule 104 translation address masquerade
```

* rule 105 to NAT Branch-1 subnet traffic

```bash
set nat source rule 105 description 'NAT branch-1'
```

```bash
set nat source rule 105 source address 100.64.0.0/29
```

```bash
set nat source rule 105 outbound-interface name eth1
```

```bash
set nat source rule 105 translation address masquerade
```

* rule 106 to NAT ICS-Branch subnet traffic

```bash
set nat source rule 106 description 'NAT ICS-branch'
```

```bash
set nat source rule 106 source address 100.67.0.0/29
```

```bash
set nat source rule 106 outbound-interface name eth1
```

```bash
set nat source rule 106 translation address masquerade
```

Save and apply configuration

```bash
commit
```

```bash
save
```

```bash
exit
```
