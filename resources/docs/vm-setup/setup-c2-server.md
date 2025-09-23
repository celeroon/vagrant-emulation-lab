# Setup C2 server

## Implement simple C2 server

In this section we will set up a primitive C2 server. I found a simple idea in an Atomic Red Team test — see:

* [https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1573/T1573.md](https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1573/T1573.md)
* [https://medium.com/walmartglobaltech/openssl-server-reverse-shell-from-windows-client-aee2dbfa0926](https://medium.com/walmartglobaltech/openssl-server-reverse-shell-from-windows-client-aee2dbfa0926)

Run the VM:

```bash
vagrant up c2-server-1
```

Access the VM by name using `vagrant ssh` or via the management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

Change network settings:

```bash
cat <<EOF | sudo tee /etc/network/interfaces > /dev/null
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address 192.168.225.3
  netmask 255.255.255.0
  pre-up sleep 2

auto eth1
iface eth1 inet static
  address 198.51.100.6
  netmask 255.255.255.248
  gateway 198.51.100.1
  dns-nameservers 8.8.8.8
  pre-up sleep 2
EOF
```

Restart networking:

```bash
sudo systemctl restart networking
```

Based on the instructions, first generate certificates:

```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

Next, enable listening on a specific port (for example, 443):

```bash
sudo openssl s_server -quiet -key key.pem -cert cert.pem -port 443
```
