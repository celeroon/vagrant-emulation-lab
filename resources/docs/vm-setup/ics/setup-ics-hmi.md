# Setup ICS HMI

In this section, we will set up an HMI node that is part of [original CybICS repository](https://github.com/mniedermaier/CybICS) 

Run VM

```bash
vagrant up ics-hmi-1
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
  address 192.168.225.194
  netmask 255.255.255.0
  gateway 192.168.225.1
  dns-nameservers 8.8.8.8

auto eth1
iface eth1 inet static
  address 172.16.95.10
  netmask 255.255.255.0
  post-up ip route add 172.16.90.0/24 via 172.16.95.254
  pre-down ip route del 172.16.90.0/24 via 172.16.95.254
EOF
```

Restart networking

```bash
sudo systemctl restart networking 
```

Next, [Install Docker with Docker Compose](/resources/docs/install-docker-compose.md)

Define OpenPLC IP address

```bash
OPENPLC_IP="172.16.90.11"
```

Clone repository and enter it

```bash
git clone https://github.com/mniedermaier/CybICS.git
cd CybICS/software/FUXA
```

Change the project json file with custom OpenPLC IP address

```bash
sed -i "s|\"address\": \"openplc:502\"|\"address\": \"${OPENPLC_IP}:502\"|" fuxa-project.json
```

Build Docker Image from locally modified source

```bash
docker build -t cybics-fuxa:local .
```

Create Docker Compose Configuration

```bash
sudo mkdir -p /opt/cybics
sudo chown $USER:$USER /opt/cybics
cd /opt/cybics
```

Create the docker compose file

```bash
cat > /opt/cybics/docker-compose.yml << 'EOF'
services:
  fuxa:
    image: cybics-fuxa:local
    restart: always
    network_mode: host
    # Port exposed on VM IP:
    # - 1881: FUXA HMI Interface
EOF
```

Deploy container

```bash
docker compose up -d
```

Access web interface: `http://192.168.225.194:1881`. Default credentials: admin/123456
