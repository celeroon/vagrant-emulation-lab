# Setup Nvidia Cumulus switch

This switch will be configured on branch-1.

Run VM

```bash
vagrant up branch-sw-1
```

Access VM:

```bash
vagrant ssh branch-sw-1
```

(or) Using SSH:

```bash
ssh vagrant@192.168.225.15 -i ~/.vagrant.d/insecure_private_key
```

Change hostname:

```bash
nv set system hostname branch-sw-1
```

Create bridge

```bash
nv set bridge domain br_default
```

Add VLAN 1 to the vlan-aware bridge domain

```bash
nv set bridge domain br_default vlan 1
```

Attach swp1 to the bridge

```bash
nv set interface swp1 bridge domain br_default
```

Make swp1 carry VLAN 1 untagged

```bash
nv set interface swp1 bridge domain br_default untagged 1
```

Create VLAN 1 SVI

```bash
nv set interface vlan1 type svi
```

Bind SVI to VLAN 1

```bash
nv set interface vlan1 vlan 1
```

Base interface is the vlan-aware bridge

```bash
nv set interface vlan1 base-interface br_default
```

Assign IP address to the SVI

```bash
nv set interface vlan1 ip address 172.30.10.253/24
```

Attach swp2 to the bridge

```bash
nv set interface swp2 bridge domain br_default
```

Make swp2 an access port in VLAN 1

```bash
nv set interface swp2 bridge domain br_default access 1
```

Commit changes

```bash
nv config apply
```
