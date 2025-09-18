# Setup FortiGate firewall

Run the VM from the main working directory

```bash
vagrant up fortigate-1
```

Let’s first set up FortiGate version 7.6 because it has limitations. Access the management IP address `192.168.225.10` via HTTPS to configure FortiGate through the GUI. Use the default username `admin` with your newly set password during the first login to register FortiGate.

Change the hostname and time zone in the settings.

<div align="center">
    <img alt="FortiGate settings" src="/resources/images/fortigate/settings-hostname-timezone.png" width="100%">
</div>

Navigate to the network settings and configure port2 - the emulated firewall Internet interface.

<div align="center">
    <img alt="FortiGate port2 settings" src="/resources/images/fortigate/port2-settings.png" width="100%">
</div>

Next, port3 will be our LAN-facing interface. As mentioned earlier, newer versions of FortiOS use a new trial license that limits interfaces. Here I will set up interface port3, but in older FortiOS versions I will configure multiple VLAN interfaces.

<div align="center">
    <img alt="FortiGate port3 settings" src="/resources/images/fortigate/port3-settings.png" width="100%">
</div>

Also add DHCP on the same interface

<div align="center">
    <img alt="FortiGate port3 settings DHCP" src="/resources/images/fortigate/port3-settings-dhcp.png" width="100%">
</div>

For FortiGate 7.2.0 and older, add all VLAN interfaces based on the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

<div align="center">
    <img alt="FortiGate 7.2.0 interface configuration" src="/resources/images/fortigate/fortigate-7-2-0-vlans.png" width="100%">
</div>

Configure performance SLA

<div align="center">
    <img alt="FortiGate SDWAN SLA" src="/resources/images/fortigate/sdwan-sla.png" width="100%">
</div>

In the SD-WAN section, go to SD-WAN Zones, edit the default `virtual-wan-link`, and add a new interface.

<div align="center">
    <img alt="FortiGate SD-WAN Zone new interface" src="/resources/images/fortigate/sdwan-new-interface.png" width="100%">
</div>

<div align="center">
    <img alt="FortiGate SD-WAN Zone new interface" src="/resources/images/fortigate/sdwan-new-interface2.png" width="100%">
</div>

In the SD-WAN section at the top of the page, navigate to SD-WAN Rules and create a new one

<div align="center">
    <img alt="FortiGate SD-WAN rule" src="/resources/images/fortigate/sdwan-rule1.png" width="100%">
</div>

<div align="center">
    <img alt="FortiGate SD-WAN rule" src="/resources/images/fortigate/sdwan-rule2.png" width="100%">
</div>

Next, we will define a default route via the SD-WAN interface to send all traffic to the Internet

<div align="center">
    <img alt="FortiGate default route" src="/resources/images/fortigate/default-route.png" width="100%">
</div>

Go to Policies. In the free version, you can enable only one simple any-to-any policy, but you can bypass this limit by enabling multiple interfaces in Feature Visibility (`System -> Feature Visibility -> Multiple Interface Policies -> Apply`). Using this technique, you can then create policies from/to multiple interfaces.

But in our case, only one network will have access to the Internet. If you want to deploy multiple networks (multiple interfaces), you can later create a policy with the from/to interface set to any - though this is not recommended in a production environment.

<div align="center">
    <img alt="FortiGate Policies" src="/resources/images/fortigate/policy1.png" width="100%">
</div>

<div align="center">
    <img alt="FortiGate Policies" src="/resources/images/fortigate/policy2.png" width="100%">
</div>

On FortiGate 7.2.0 (or older), the policy will look like this

<div align="center">
    <img alt="FortiGate Policies" src="/resources/images/fortigate/policy3.png" width="100%">
</div>

Complete the firewall policy on FortiGate 7.2.0 (or older) as shown below.

<div align="center">
    <img alt="FortiGate Policies" src="/resources/images/fortigate/policy4.png" width="100%">
</div>

Remember, if you are using newer versions, you need to create **two policies**:

1. The first policy — source interface: `vlan10`, destination: `sdwan` interface with NAT enabled.
2. The second policy — you can experiment with `any <-> any` interfaces with NAT disabled.

Alternatively, you can create a rule from `ipsec-vpn` to `vlan10` to test one-way connectivity, and then replace `vlan10` with `ipsec-vpn` for testing, due to firewall policy limitations in newer FortiOS versions.

To collect logs from FortiGate in ELK, configure syslog via the CLI

```bash
config log syslogd setting 
 set status enable
 set server 172.16.10.10
 set port 5145
 set source-ip 192.168.20.254
 set format rfc5424
end
```

<div align="center">
    <img alt="FortiGate syslog CLI" src="/resources/images/fortigate/syslog-cli.png" width="100%">
</div>

You can generate test logs using `diag log test` - this can help you see test logs on your dashboard later, after deploying Elasticsearch.

You can use FortiGate as a local DNS server to map lab hosts, such as the email server shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg). First, navigate to `Settings -> Feature Visibility -> Additional Features` and enable *DNS Database*. Then, go to `Network -> DNS Server`, create a new DNS Database, provide the DNS Zone and Domain Name, and add a new DNS Entry.


<div align="center">
    <img alt="FortiGate DNS Server" src="/resources/images/fortigate/dns-server.png" width="100%">
</div>

**Apply the DNS Database configuration** and go back to the DNS Servers section. Add the interfaces in *DNS Service on Interface* (this may vary depending on your FortiGate version).

<div align="center">
    <img alt="FortiGate DNS Service on Interface" src="/resources/images/fortigate/dns-service-interface.png" width="100%">
</div>

Remember to change the DNS server in the interface settings under DHCP server (for users). You can also add DNS manually on the VMs in other subnets later (if you are using FortiGate 7.2.0 or older).

In this lab environment, I will also enable **SNMP v1/v2c**, which can be helpful for demo purposes later.

<div align="center">
    <img alt="FortiGate DNS Service on Interface" src="/resources/images/fortigate/snmp-v1.png" width="100%">
</div>

Remember to enable **SNMP** in the interface *Administrative Access* settings — in my case, this will be VLAN10.

**For future use, let’s set up an IPsec Site-to-Site VPN** to the branch (Cisco) router.

* Navigate to `VPN -> IPsec Wizard` and create a *Custom* VPN with any name.
* Select `port2` as the lab WAN interface and set the remote peer (router) address to `100.64.0.6`.
* In the Authentication section, choose `IKE version 2` and set the password to `vagrant`.
* In the Phase 2 section, leave only one option for encryption and authentication: select `DES` and `SHA1`. For Diffie-Hellman Group, select only group `2`.
* In the Phase 2 settings:

  * On FortiGate 7.6, set the Local Address to `172.16.10.0/24`.
  * On FortiGate 7.2.0 or older, set it to the user network `172.16.20.0/24`.
  * The Remote Network must be the branch network `172.30.10.0/24`.
* For the Phase 2 proposal, again keep only one option for encryption and authentication: `DES` and `SHA1`. Set DH Group to `2` and change *Seconds* to `3600`.

**Now create Firewall Policies.** With Site-to-Site VPN you need to define multiple rules. Make sure that the *multiple interfaces* feature is enabled.

* Allow traffic between the remote network and the local user network (NAT disabled).
* If you clone an existing rule, make sure to enable it.
* In all cases, ensure that **All Sessions** is enabled for *Log Allowed Traffic*.

<div align="center">
    <img alt="FortiGate Firewall Policy" src="/resources/images/fortigate/firewall-policy-2.png" width="100%">
</div>

Go to `Network -> Static Route` and create a new entry for the remote network.

<div align="center">
    <img alt="Static route remote network" src="/resources/images/fortigate/static-route-remote.png" width="100%">
</div>

To view IPsec VPN tunnel statistics, add the **IPsec** widget to the *Status* page.

<div align="center">
    <img alt="IPSec widget" src="/resources/images/fortigate/ipsec-widget.png" width="100%">
</div>