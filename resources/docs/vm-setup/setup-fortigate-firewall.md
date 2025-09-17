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

For FortiGate 7.2.0 and older, add all VLAN interfaces based on the [topology](/resources/images/vagrant-lab-virtual-topology.svg)

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

On FortiGate 7.2.0 (or older) implementation the policy will looks like

<div align="center">
    <img alt="FortiGate Policies" src="/resources/images/fortigate/policy3.png" width="100%">
</div>

To collect logs from FortiGate in ELK, we need to configure syslog via the CLI

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

You can use FortiGate as a local DNS server to map lab hosts like email server on [topology](/resources/images/vagrant-lab-virtual-topology.svg). First navigate to the `Settings -> Feature Visibility -> Additional Features -> (enable) DNS Database`. Now in the `Network -> DNS Server` section under DNS Database create new, next provide DNS Zone, Domain Name and create new DNS Entry

<div align="center">
    <img alt="FortiGate DNS Server" src="/resources/images/fortigate/dns-server.png" width="100%">
</div>

Apply DNS Database configuration and move back to the DNS Servers section and add interfaces in the DNS Service on Interface (based on your deployed FortiGate version)

<div align="center">
    <img alt="FortiGate DNS Service on Interface" src="/resources/images/fortigate/dns-service-interface.png" width="100%">
</div>

Remember to change DNS server on the interface settings in the DHCP server settings (for users). You can add DNS on the VMs on another subnets manually later during deploying (if you have FortiGate 7.2.0 or older).

In this lab environment I will also enable SNMP v1/v2c, later it could be helpfull for demo purposes.

<div align="center">
    <img alt="FortiGate DNS Service on Interface" src="/resources/images/fortigate/snmp-v1.png" width="100%">
</div>

Remember to enable `SNMP` as the interface `Administrative Access` - in my case it will be VLAN10.

For the future use lets setup IPSec Site to Site VPN to branch (Cisco) router. Navigate to the `VPN -> IPsec Wizard` and create custom with any name. Next select `port2` as a lab WAN interface and provide remote peer (router) address `100.64.0.6`. In the Authentication section select `IKE version 2` and put password as `vagrant`. In the Phase2 section leave only 1 box for encryption and authentication and select `DES` and `SHA1`, Diffie-Hellman Group - only `2`. Move next and in the Phase2 settings if you have FortiGate 7.6 deploy as a Local Address just provide `172.16.10.0/24`, but if you have FortiGate 7.2.0 or older put users network - `172.16.20.0/24`. The Remote Network must be branch network - `172.30.10.0/24`. Move down and for Phase 2 proposal leave only 1 box for encryption and authentication and select `DES` and `SHA1`, for DH Group select only group `2` and at the end change Seconds to `3600`.

Now we need to create Firewall Policies. With Site to Site VPN implementation you need to define multiple rules. Be sure that feature multiple interfaces is enabled.

Allow traffic to and from remote network to local user network, NAT is disabled. Enable rule if you clone previos.

<div align="center">
    <img alt="FortiGate Firewall Policy" src="/resources/images/fortigate/firewall-policy-2.png" width="100%">
</div>

In both cases make sure `All Sessions` for Log Allowed Traffic is enabled

Move to the `Network -> Static Route` and create new entry for remote network

<div align="center">
    <img alt="Static route remote network" src="/resources/images/fortigate/static-route-remote.png" width="100%">
</div>

To get IPSec VPN tunnel statistics you can add `IPSec` widget on a Status page

<div align="center">
    <img alt="IPSec widget" src="/resources/images/fortigate/ipsec-widget.png" width="100%">
</div>