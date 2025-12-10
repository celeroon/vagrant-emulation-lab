# Setup ICS FortiGate firewall

Run the VM from the main working directory

```bash
vagrant up fortigate-ics-1
```

Access FortiGate via browser or SSH on mgmt IP `192.168.225.190` and configure below:

* Add address for `port2` with `100.67.0.6/29` 
* Add new static route to `0.0.0.0/0` via `100.67.0.1` under `port2`
* Create new `VLAN90` interface under `port3` with IP address `172.16.90.254/24`
* Create new `VLAN95` interface under `port3` with IP address `172.16.95.254/24`
* Create a simple firewall policy to allow from any to any interface and as source and destination network also put all. Disable NAT - it will allow traffic only between local networks. Internet access will be available from management network (192.168.225.0/24) to not create a lot of traffic on VLAN90 and VLAN95.
