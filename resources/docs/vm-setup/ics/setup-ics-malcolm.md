# Setup ICS Malcolm

In this section, we will set up a [Malcolm](https://malcolm.fyi/) node

> [!WARNING]
> This VM requires more CPU and RAM

Run VM

```bash
vagrant up ics-malcolm-1
```

Access the VM by name using `vagrant ssh` or via the management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

Configure networking

```bash
sudo tee /etc/network/interfaces <<EOF
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address 192.168.225.196
  netmask 255.255.255.0
  gateway 192.168.225.1
  dns-nameservers 8.8.8.8

auto eth1
iface eth1 inet manual
  up ip link set eth1 up promisc on allmulticast on
  down ip link set eth1 down
EOF
```

Restart networking

```bash
sudo systemctl restart networking 
```

Next, [Install Docker with Docker Compose](/resources/docs/install-docker-compose.md)

Copy Malcolm repo and enter it

```bash
git clone https://github.com/idaholab/Malcolm.git
cd Malcolm/
```

Install additional packages

```bash
sudo apt install python3-ruamel.yaml python3-dotenv python3-dialog dialog -y
```

Run installation script

```bash
sudo ./scripts/install.py
```

In the installation step you need to enable Suricata rules, Zeek for ICS/OT and capture live network traffic on interface eth1

<div align="center">
    <img alt="Malcolm install" src="/resources/images/ics/malcolm-install.png" width="100%">
</div>

In the next step:

* Automatically Apply System Tweaks -> Yes
* Pull Malcolm Images -> Yes
* Save and continue -> Accept config

After automatically pulling images (if you do not select this option run: `docker compose --profile malcolm pull`), start Malcolm:

```bash
./scripts/start
```

In the Configuration Authentication select:

* all
* Select authentication method (basic) -> Yes
* Store administrator username/password for basic HTTP authentication -> Yes
* Provide new login and password for administrator user
* Regenerate internal passwords for local primary OpenSearch instance ? -> Yes
* Store username/password for OpenSearch Alerting email sender account ? -> No
* Regenerate internal passwords for NetBox ? -> Yes
* Regenerate internal superuser passwords for PostgreSQL ? -> Yes
* Regenerate internal passwords for Redis ? -> Yes
* Store password hash secret for Arkime view cluster ? Yes (here I put cleartext password)

Access Malcolm via web browser: `https://192.168.225.196/`

> [!WARNING]
> Remember to run additional commands in the next step to see traffic on Malcolm.
