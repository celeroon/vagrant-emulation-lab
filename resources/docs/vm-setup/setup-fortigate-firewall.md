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
