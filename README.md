# Build a Networking & Cybersecurity Lab with Vagrant

Project goal: deploy a virtual infrastructure using automation tools to provide an environment (with pre installed programs and tools) to emulate adversaries and detect them based on free and open source tools and researched techniques of red and blue teaming (purple team).

The core lab components consist of a firewall (FortiGate), switches (OVS, Cumulus), routers (Cisco 8kv, VyOS), C2, email, and a payload server. On the LAN, the main components are SIEM (ELK), Windows Servers, databases, (web) applications, sandbox, SOAR, DFIR tools and workstations. 

This project will grow with ideas for emulation techniques - both custom and documented. The goal is to follow the MITRE ATT&CK matrix, starting from the initial stages and progressing upward, with examples of how to run scenarios and detect them (rules) using a close to real virtual infrastructure.

## Lab Topology

The topology of this project will change from time to time. I will add new guides on how to implement new tools in the lab.

<div align="center">
    <img alt="Vagrant Lab Virtual Topology" src="/resources/images/vagrant-lab-virtual-topology.svg" width="100%">
</div>

* [Lab Implementation Overview](/resources/docs/lab-implementation-overview.md)

## Manual lab setup

This section provides guidelines for setting up the lab environment manually and can help anyone interested in a step-by-step implementation.

* [Requirements](/resources/docs/lab-requirements.md)
* [Host setup (Debian based system)](/resources/docs/host-debian-setup.md)
* [Build FortiGate Vagrant (libvirt) box](/resources/docs/vagrant-libvirt/build-fortigate-vagrant-libvirt-box.md)
* [Build Cisco cat8kv Vagrant (libvirt) box](/resources/docs/vagrant-libvirt/build-cisco-cat8kv-vagrant-libvirt-box.md)
* [Build Windows 11/2025 Vagrant (libvirt) box](/resources/docs/vagrant-libvirt/build-windows-11-2025-libvirt-box.md)
<!-- * [Build NethSecurity firewall Vagrant (libvirt) box](/resources/docs/vagrant-libvirt/build-nethsecurity-firewall-vagrant-libvirt-box.md) -->

### Setup VMs

VM implementations are divided into logical network segments as shown in the topology. Follow the implementation order below to ensure all components work successfully.

#### Internet Segment

* [VyOS router](/resources/docs/vm-setup/setup-vyos-router.md)
* [Kali Linux](/resources/docs/vm-setup/setup-kali-linux.md)
* [Email server](/resources/docs/vm-setup/setup-email-server.md)
* [C2 server](/resources/docs/vm-setup/setup-c2-server.md)
<!-- * [Payload server](/resources/docs/vm-setup/setup-payload-server.md) -->

#### HQ Server Segment

<!-- * [Nethsecurity firewall](/resources/docs/vm-setup/setup-nethsecurity-firewall.md) -->
* [FortiGate firewall](/resources/docs/vm-setup/setup-fortigate-firewall.md)
* [Open vSwitch](/resources/docs/vm-setup/setup-ovs-switches.md)
* [ELK](/resources/docs/vm-setup/setup-elk.md)
* [Velociraptor](/resources/docs/vm-setup/setup-velociraptor.md)
* [n8n](/resources/docs/vm-setup/setup-n8n.md)
* [DFIR-IRIS](/resources/docs/vm-setup/setup-dfir-iris.md)
* [CAPEv2](/resources/docs/vm-setup/setup-capev2.md)
* [Cuckoo3](/resources/docs/vm-setup/setup-cuckoo3.md)
<!-- * [Windows server](/resources/docs/vm-setup/setup-windows-server.md) -->

#### HQ User Segment

* [NAS](/resources/docs/vm-setup/setup-nas.md)
* [Windows workstation](/resources/docs/vm-setup/setup-windows-workstation.md)

#### Branch-1 Segment

* [Cisco Catalyst 8kv router](/resources/docs/vm-setup/setup-cisco-8kv-router.md)
* [Cumulus switch](/resources/docs/vm-setup/setup-cumulus-switches.md)
* [Branch host](/resources/docs/vm-setup/setup-branch-host.md)

---

## Auto lab setup

* [FortiGate firewall](/resources/docs/vm-auto-setup/auto-setup-fortigate-firewall.md)

---

## Scenarios (attack and detect)

Execution sequence workflow #1

1. [Suspicious Configuration Change Sequence on Cisco IOS Device](https://github.com/celeroon/vagrant-emulation-lab/blob/main/resources/attack-detect-scenarios/initial-access/network-service/common-service-attack/Suspicious-Configuration-Change-Sequence-on-Cisco-IOS-Device/Suspicious-Configuration-Change-Sequence-on-Cisco-IOS-Device.md)
2. [Suspicious Gateway Network Scan](https://github.com/celeroon/vagrant-emulation-lab/blob/main/resources/attack-detect-scenarios/reconnaissance/networkidiscovery-and-port-scanning/Suspicious-Gateway-Network-Scan/Suspicious-Gateway-Network-Scan.md)
3. [Remote connection followed by suspicious process execution](https://github.com/celeroon/vagrant-emulation-lab/blob/main/resources/attack-detect-scenarios/initial-access/remote-admin-tools-windows/remote-connection-followed-by-suspicious-process-execution/Remote-connection-followed-by-suspicious-process-execution.md)
4. [Suspicious PowerShell Download and Execute Pattern](https://github.com/celeroon/vagrant-emulation-lab/blob/main/resources/attack-detect-scenarios/execution/suspicious-powershell-download-and-execute-pattern/Suspicious-PowerShell-Download-and-Execute-Pattern.md)

This section will provide instructions on how to generate events, build queries, and create Elastic rules to detect malicious activity in the lab environment. These scenarios are categorized based on the [MITRE ATT&CK](https://attack.mitre.org/) framework.

- **Reconnaissance**
    - Network Discovery and Port Scanning
        - [Suspicious Gateway Network Scan](/resources/attack-detect-scenarios/reconnaissance/networkidiscovery-and-port-scanning/Suspicious-Gateway-Network-Scan/Suspicious-Gateway-Network-Scan.md)
- **Initial Access**
    - Network service
        - Common service attack
            - [Suspicious Configuration Change Sequence on Cisco IOS Device](/resources/attack-detect-scenarios/initial-access/network-service/common-service-attack/Suspicious-Configuration-Change-Sequence-on-Cisco-IOS-Device/Suspicious-Configuration-Change-Sequence-on-Cisco-IOS-Device.md)
    - Remote Admin Tools (Windows)
        - [Remote connection followed by suspicious process execution](/resources/attack-detect-scenarios/initial-access/remote-admin-tools-windows/remote-connection-followed-by-suspicious-process-execution/Remote-connection-followed-by-suspicious-process-execution.md)
- **Execution**
    - PowerShell
        - [Suspicious PowerShell Download and Execute Pattern](/resources/attack-detect-scenarios/execution/suspicious-powershell-download-and-execute-pattern/Suspicious-PowerShell-Download-and-Execute-Pattern.md)
---

## n8n workflows

This section will provide instructions on how to create n8n workflows based on the Elastic rules above, adding automation, enrichment, AI analysis, case management, report generation, integration with other solutions, and much more.

* [Suspicious Configuration Change Sequence on Cisco IOS Device](/resources/n8n-workflows/Suspicious-Configuration-Change-Sequence-on-Cisco-IOS-Device/n8n-Suspicious-Configuration-Change-Sequence-on-Cisco-IOS-Device.md)
* [Suspicious PowerShell Download and Execute Pattern](/resources/n8n-workflows/Suspicious-PowerShell-Download-and-Execute-Pattern/n8n-Suspicious-PowerShell-Download-and-Execute-Pattern.md)

## Disclaimer

This project is for **educational and research use in a closed, virtual lab environment only**. Do **not** use any techniques, tools, or configurations from this repository against real systems, production networks, or assets you do not own or lack explicit written permission to test. Always comply with all applicable laws, regulations, licenses, and organizational policies.
The authors and contributors assume **no responsibility or liability** for any misuse, damage, loss of data, service disruption, or legal consequences arising from the use of this material. **No warranty** is provided - use at your own risk.

## Safety & scope

* Do not deploy any part of this lab to production.
* Use only synthetic/test data and isolated networks.
* Obtain explicit authorization before any security testing.
* Review all third-party tool licenses and terms before use.

## Trademarks

All product names, logos, brands, and other trademarks mentioned in this project are the property of their respective owners. Any use of third-party names is for identification purposes only and does **not** imply affiliation, sponsorship, or endorsement. This project is not affiliated with, sponsored by, or endorsed by any vendor or solution referenced.
