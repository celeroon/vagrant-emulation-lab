# Build a Networking & Cybersecurity Lab with Vagrant

Project goal: deploy a virtual infrastructure using automation tools to provide an environment (with pre installed programs and tools) to emulate adversaries and detect them based on free and open source tools and researched techniques of red and blue teaming (purple team).

The core lab components consist of a firewall (FortiGate), switches (OVS, Cumulus), routers (Cisco 8kv, VyOS), C2, email, and a payload server. On the LAN, the main components are SIEM (ELK), Windows Servers, databases, (web) applications, sandbox, SOAR, DFIR tools and workstations. 

## Lab Topology

The topology of this project will change from time to time. I will add new guides on how to implement new tools in the lab.


<div align="center">
    <img alt="Vagrant Lab Virtual Topology" src="/resources/images/vagrant-lab-virtual-topology.svg" width="100%">
</div>

## Lab setup instructions

* [Requirements](/resources/docs/lab-requirements.md)
* [Host setup (Debian based system)](/resources/docs/host-debian-setup.md)
* [Build FortiGate Vagrant (libvirt) box](/resources/docs/vagrant-libvirt/build-fortigate-vagrant-libvirt-box.md)
<!-- * [Build NethSecurity firewall Vagrant (libvirt) box](/resources/docs/vagrant-libvirt/build-nethsecurity-firewall-vagrant-libvirt-box.md) -->
* [Build Cisco cat8kv Vagrant (libvirt) box](/resources/docs/vagrant-libvirt/build-cisco-cat8kv-vagrant-libvirt-box.md)
* [Build Windows 11/2025 Vagrant (libvirt) box](/resources/docs/vagrant-libvirt/build-windows-11-2025-libvirt-box.md)

### Setup VMs

* [VyOS router](/resources/docs/vm-setup/setup-vyos-router.md)
* [Cisco Catalyst 8kv router](/resources/docs/vm-setup/setup-cisco-8kv-router.md)
* [FortiGate firewall](/resources/docs/vm-setup/setup-fortigate-firewall.md)
<!-- * [Nethsecurity firewall](/resources/docs/vm-setup/setup-nethsecurity-firewall.md) -->
* [Open vSwitch](/resources/docs/vm-setup/setup-ovs-switches.md)
* [Cumulus switch](/resources/docs/vm-setup/setup-cumulus-switches.md)
* [ELK](/resources/docs/vm-setup/setup-elk.md)
* [Velociraptor](/resources/docs/vm-setup/setup-velociraptor.md)
* [n8n](/resources/docs/vm-setup/setup-n8n.md)
* [DFIR-IRIS](/resources/docs/vm-setup/setup-dfir-iris.md)
<!-- * [Windows server](/resources/docs/vm-setup/setup-windows-server.md) -->
* [NAS](/resources/docs/vm-setup/setup-nas.md)
* [Kali Linux](/resources/docs/vm-setup/setup-kali-linux.md)
<!-- * [Payload server](/resources/docs/vm-setup/setup-payload-server.md) -->
* [Email server](/resources/docs/vm-setup/setup-email-server.md)
* [C2 server](/resources/docs/vm-setup/setup-c2-server.md)
* [Windows workstation](/resources/docs/vm-setup/setup-windows-workstation.md)
* [Branch host](/resources/docs/vm-setup/setup-branch-host.md)
