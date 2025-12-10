# Setup ICS OpenPLC

In this section, we will set up an OpenPLC node that is part of [original CybICS repository](https://github.com/mniedermaier/CybICS) 

Run VM

```bash
vagrant up ics-openplc-1
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
  address 192.168.225.193
  netmask 255.255.255.0
  gateway 192.168.225.1
  dns-nameservers 8.8.8.8
  
auto eth1
iface eth1 inet static
  address 172.16.90.11
  netmask 255.255.255.0
  post-up ip route add 172.16.95.0/24 via 172.16.90.254
  pre-down ip route del 172.16.95.0/24 via 172.16.90.254
EOF
```

Restart networking

```bash
sudo systemctl restart networking 
```

Next, [Install Docker with Docker Compose](/resources/docs/install-docker-compose.md)

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
  openplc:
    image: mniedermaier1337/cybicsopenplc:latest
    restart: always
    privileged: true
    network_mode: host
    # Ports exposed on VM IP:
    # - 8080: OpenPLC Web Interface
    # - 502: Modbus TCP
    # - 102: Siemens S7
    # - 44818: EtherNet/IP
    # - 20000: DNP3
EOF
```

Deploy container

```bash
docker compose up -d
```

Access web interface: `http://192.168.225.193:8080/login`. Default credentials: openplc/openplc
