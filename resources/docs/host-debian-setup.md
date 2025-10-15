# Initial Debian based host setup

Make sure the virtualization is enabled

```bash
grep -E '^flags.*(vmx|svm)' /proc/cpuinfo
```

Install git

```bash
sudo apt update && sudo apt install git -y
```

Clone project

```bash
git clone https://github.com/celeroon/vagrant-libvirt-labs $HOME/vagrant-libvirt-labs
```

Go to the project directory (this will be the main working directory for this project):

```bash
cd $HOME/vagrant-libvirt-labs
```

- [Install RDP with Xrdp](#install-rdp-with-xrdp)
- [Install system packages](#install-system-packages)
- [Install Python3 pip](#install-python3-pip)
- [Setup libvirt](#setup-libvirt)
- [Install Vagrant](#install-vagrant)
- [Install Packer](#install-packer)
- [Create lab networks](#create-lab-networks)
- [Setup iptables](#setup-iptables)
- [Install Guacamole](#install-guacamole)
- [Disable offload](#disable-offload)

## Install RDP with Xrdp

Main resource: [Guide to Set Up Remote Desktop (RDP) with Xrdp on Debian 12](https://www.howtoforge.com/guide-to-set-up-remote-desktop-with-xrdp-on-debian-12/)

### Installing Desktop Environment

Install tasksel

```bash
sudo apt install tasksel
```

Select XFCE (DE)

```bash
sudo tasksel
```

### Installing Xrdp

After installing XFCE it is time to install XRDP 

```bash
sudo apt install xrdp
```

Run and enable Xrdp service

```bash
sudo systemctl start xrdp
sudo systemctl enable xrdp
```

### Configure Xrdp

Create new directory for TLS certificates

```bash
sudo mkdir -p /etc/xrdp/certs
```

Generate Self-Signed certificates

```bash
sudo openssl req -x509 -newkey rsa:2048 -nodes -keyout /etc/xrdp/certs/key.pem -out /etc/xrdp/certs/cert.pem -days 3650
```

Change the ownership of the directory

```bash
sudo chown -R xrdp:xrdp /etc/xrdp/certs
sudo chmod 0644 /etc/xrdp/certs/cert.pem
sudo chmod 0600 /etc/xrdp/certs/key.pem
```

Edit xrdp configuration

```bash
sudo nano /etc/xrdp/xrdp.ini
```

Change settings as below

```bash
security_layer=tls
certificate=/etc/xrdp/certs/cert.pem
key_file=/etc/xrdp/certs/key.pem
ssl_protocols=TLSv1.2, TLSv1.3
```

Restart the xrdp service

```bash
sudo systemctl restart xrdp
```

Sometime reboot is required

## Install system packages

Install required system packages and tools

```bash
sudo apt install -y \
    build-essential make patch ruby-dev \
    python3-dev libffi-dev libssl-dev libreadline-dev libsqlite3-dev \
    libbz2-dev liblzma-dev zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev \
    qemu-kvm virt-manager virtinst libguestfs-tools libvirt-dev libvirt-daemon-system libvirt-clients \
    iptables iptables-persistent bridge-utils ethtool \
    curl wget unzip p7zip-full jq expect \
    apt-transport-https ca-certificates software-properties-common \
    spice-client-gtk cockpit cockpit-machines
```

Enable and start the cockpit service

```bash
sudo systemctl enable --now cockpit.socket
```

## Install Python3-pip

Install pip3 and venv

```bash
sudo apt install python3-pip python3-venv -y
```

Create virtual environment

```bash
python3 -m venv ./ansible/ansible-venv
```

Upgrade pip in the virtual environment

```bash
./ansible/ansible-venv/bin/python -m pip install --upgrade pip
```

> [!NOTE]  
> Ansible will be installed for future use

Install Python pip packages into the venv

```bash
./ansible/ansible-venv/bin/python -m pip install -r ./ansible/requirements.txt -v
```

Verify ansible-core installation

```bash
./ansible/ansible-venv/bin/ansible --version
```

Install ansible collections

```bash
./ansible/ansible-venv/bin/ansible-galaxy collection install \
  -r ansible/requirements.yml -p ./ansible/collections
```

## Setup libvirt

Add user to kvm and libvirt groups

```bash
sudo usermod -aG kvm $(whoami)
sudo usermod -aG libvirt $(whoami)
```

Start the libvirtd service:

```bash
sudo systemctl start libvirtd
```

Enable the libvirtd service:

```bash
sudo systemctl enable libvirtd
```

Create a new session for the user to apply group changes. Run the command below, log out and log back in, or simply restart the host:

```bash
su - <USERNAME>
```

Set parameters in `/etc/libvirt/libvirtd.conf` to allow non-root users (that are members of the `libvirt` group) to interact with libvirt services:

```bash
sudo sed -i 's|^#\?unix_sock_group\s*=.*|unix_sock_group = "libvirt"|' /etc/libvirt/libvirtd.conf
```

```bash
sudo sed -i 's|^#\?unix_sock_ro_perms\s*=.*|unix_sock_ro_perms = "0777"|' /etc/libvirt/libvirtd.conf
```

```bash
sudo sed -i 's|^#\?unix_sock_rw_perms\s*=.*|unix_sock_rw_perms = "0770"|' /etc/libvirt/libvirtd.conf
```

Restart libvirt service:

```bash
sudo systemctl restart libvirtd
```

> [!TIP]
> In a newer version libvirt backend changed from iptables to nftables (https://gitlab.com/libvirt/libvirt/-/issues/645). Check the `firewall_backend` in the `/etc/libvirt/network.conf`. You may change it to the `iptables` and restart `libvirtd` service.


## Install Vagrant

To install Vagrant you need to download a DEB package and install it. Vagrant 2.4.9 version will be used:

```bash
VAGRANT_VERSION=2.4.9
```

Download the .deb package

```bash
wget -O /tmp/vagrant-${VAGRANT_VERSION}-1_amd64.deb \
"https://releases.hashicorp.com/vagrant/${VAGRANT_VERSION}/vagrant_${VAGRANT_VERSION}-1_amd64.deb"
```

Install the .deb package

```bash
sudo apt install -y /tmp/vagrant-${VAGRANT_VERSION}-1_amd64.deb
```

Clean up

```bash
rm -f /tmp/vagrant-${VAGRANT_VERSION}-1_amd64.deb
```

Verify installation

```bash
vagrant --version
```

Install Vagrant plugins:

```bash
vagrant plugin install vagrant-scp winrm winrm-elevated
```

Install `vagrant-libvirt` plugin with 0.9.0 version (time tested)

```bash
vagrant plugin install vagrant-libvirt --plugin-version 0.9.0
```

Make Vagrant's Ruby and gem the default:

```bash
echo 'export PATH="/opt/vagrant/embedded/bin:$PATH"' >> ~/.bashrc && source ~/.bashrc
```

Install rexml plugin with sudo:

```bash
sudo /opt/vagrant/embedded/bin/gem install rexml
```

Download required vagrant boxes

```bash
vagrant box add --provider libvirt generic-x64/debian11
vagrant box add --provider libvirt generic-x64/debian12
vagrant box add --provider libvirt vyos/current
vagrant box add --provider libvirt aarna/cumulus-vx-5.11.1
vagrant box add --provider libvirt joaobrlt/ubuntu-desktop-24.04
vagrant box add --provider libvirt kalilinux/rolling
vagrant box add --provider libvirt generic/ubuntu2204
```

For Windows I recommend boxes from [peru](https://portal.cloud.hashicorp.com/vagrant/discover/peru) but later I will show how to build Windows 11/2025 box. If you want to deploy [CAPEv2](https://github.com/kevoreilly/CAPEv2) sandbox later you need to download windows 10 box:

```bash
vagrant box add --provider libvirt peru/windows-10-enterprise-x64-eval
```

```bash
vagrant box add --provider libvirt peru/windows-server-2022-standard-x64-eval
```

## Install Packer

Get codename

```bash
CODENAME=$(grep -Po 'VERSION_CODENAME=\K.*' /etc/os-release)
```

Add HashiCorp GPG key

```bash
wget -O- https://apt.releases.hashicorp.com/gpg | \
  sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg --yes
```

Add HashiCorp repository

```bash
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com ${CODENAME} main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list
```

Update package index

```bash
sudo apt update
```

Install Packer

```bash
sudo apt install -y packer
```


Install required Packer plugins for QEMU and Vagrant

```bash
packer plugins install github.com/hashicorp/qemu
packer plugins install github.com/hashicorp/vagrant
```

## Create lab networks


Create network that will NAT lab traffic:

```bash
cat > lab-internet.xml <<EOF
<network>
  <name>lab-internet</name>
  <bridge name='virbr10'/>
  <forward mode='nat'/>
  <ip address='10.1.1.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.1.1.10' end='10.1.1.20'/>
    </dhcp>
  </ip>
</network>
EOF
```

Create management network with DHCP reservation: 

```bash
cat > vagrant-mgmt.xml <<EOF
<network>
  <name>vagrant-mgmt</name>
  <bridge name='virbr225'/>
  <forward mode='nat'/>
  <ip address='192.168.225.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.225.230' end='192.168.225.250'/>
      <host mac='52:54:02:54:00:02' ip='192.168.225.2'/>
      <host mac='52:54:02:54:00:03' ip='192.168.225.3'/>
      <host mac='52:54:02:54:00:04' ip='192.168.225.4'/>
      <host mac='52:54:02:54:00:05' ip='192.168.225.5'/>
      <host mac='52:54:02:54:00:06' ip='192.168.225.6'/>
      <host mac='52:54:02:54:00:07' ip='192.168.225.7'/>
      <host mac='52:54:02:54:00:08' ip='192.168.225.8'/>
      <host mac='52:54:02:54:00:09' ip='192.168.225.9'/>
      <host mac='52:54:02:54:00:10' ip='192.168.225.10'/>
      <host mac='52:54:02:54:00:11' ip='192.168.225.11'/>
      <host mac='52:54:02:54:00:12' ip='192.168.225.12'/>
      <host mac='52:54:02:54:00:13' ip='192.168.225.13'/>
      <host mac='52:54:02:54:00:14' ip='192.168.225.14'/>
      <host mac='52:54:02:54:00:15' ip='192.168.225.15'/>
      <host mac='52:54:02:54:00:16' ip='192.168.225.16'/>
      <host mac='52:54:02:54:00:17' ip='192.168.225.17'/>
      <host mac='52:54:02:54:00:18' ip='192.168.225.18'/>
      <host mac='52:54:02:54:00:19' ip='192.168.225.19'/>
      <host mac='52:54:02:54:00:20' ip='192.168.225.20'/>
      <host mac='52:54:02:54:00:21' ip='192.168.225.21'/>
      <host mac='52:54:02:54:00:22' ip='192.168.225.22'/>
      <host mac='52:54:02:54:00:23' ip='192.168.225.23'/>
      <host mac='52:54:02:54:00:24' ip='192.168.225.24'/>
      <host mac='52:54:02:54:00:25' ip='192.168.225.25'/>
      <host mac='52:54:02:54:00:26' ip='192.168.225.26'/>
      <host mac='52:54:02:54:00:27' ip='192.168.225.27'/>
      <host mac='52:54:02:54:00:28' ip='192.168.225.28'/>
      <host mac='52:54:02:54:00:29' ip='192.168.225.29'/>
      <host mac='52:54:02:54:00:30' ip='192.168.225.30'/>
      <host mac='52:54:02:54:00:31' ip='192.168.225.31'/>
      <host mac='52:54:02:54:00:32' ip='192.168.225.32'/>
      <host mac='52:54:02:54:00:33' ip='192.168.225.33'/>
      <host mac='52:54:02:54:00:34' ip='192.168.225.34'/>
      <host mac='52:54:02:54:00:35' ip='192.168.225.35'/>
      <host mac='52:54:02:54:00:36' ip='192.168.225.36'/>
      <host mac='52:54:02:54:00:37' ip='192.168.225.37'/>
      <host mac='52:54:02:54:00:38' ip='192.168.225.38'/>
      <host mac='52:54:02:54:00:39' ip='192.168.225.39'/>
      <host mac='52:54:02:54:00:40' ip='192.168.225.40'/>
      <host mac='52:54:02:54:00:41' ip='192.168.225.41'/>
      <host mac='52:54:02:54:00:42' ip='192.168.225.42'/>
      <host mac='52:54:02:54:00:43' ip='192.168.225.43'/>
      <host mac='52:54:02:54:00:44' ip='192.168.225.44'/>
      <host mac='52:54:02:54:00:45' ip='192.168.225.45'/>
      <host mac='52:54:02:54:00:46' ip='192.168.225.46'/>
      <host mac='52:54:02:54:00:47' ip='192.168.225.47'/>
      <host mac='52:54:02:54:00:48' ip='192.168.225.48'/>
      <host mac='52:54:02:54:00:49' ip='192.168.225.49'/>
      <host mac='52:54:02:54:00:50' ip='192.168.225.50'/>
      <host mac='52:54:02:54:00:51' ip='192.168.225.51'/>
      <host mac='52:54:02:54:00:52' ip='192.168.225.52'/>
      <host mac='52:54:02:54:00:53' ip='192.168.225.53'/>
      <host mac='52:54:02:54:00:54' ip='192.168.225.54'/>
      <host mac='52:54:02:54:00:55' ip='192.168.225.55'/>
      <host mac='52:54:02:54:00:56' ip='192.168.225.56'/>
      <host mac='52:54:02:54:00:57' ip='192.168.225.57'/>
      <host mac='52:54:02:54:00:58' ip='192.168.225.58'/>
      <host mac='52:54:02:54:00:59' ip='192.168.225.59'/>
      <host mac='52:54:02:54:00:60' ip='192.168.225.60'/>
      <host mac='52:54:02:54:00:61' ip='192.168.225.61'/>
      <host mac='52:54:02:54:00:62' ip='192.168.225.62'/>
      <host mac='52:54:02:54:00:63' ip='192.168.225.63'/>
      <host mac='52:54:02:54:00:64' ip='192.168.225.64'/>
      <host mac='52:54:02:54:00:65' ip='192.168.225.65'/>
      <host mac='52:54:02:54:00:66' ip='192.168.225.66'/>
      <host mac='52:54:02:54:00:67' ip='192.168.225.67'/>
      <host mac='52:54:02:54:00:68' ip='192.168.225.68'/>
      <host mac='52:54:02:54:00:69' ip='192.168.225.69'/>
      <host mac='52:54:02:54:00:70' ip='192.168.225.70'/>
      <host mac='52:54:02:54:00:71' ip='192.168.225.71'/>
      <host mac='52:54:02:54:00:72' ip='192.168.225.72'/>
      <host mac='52:54:02:54:00:73' ip='192.168.225.73'/>
      <host mac='52:54:02:54:00:74' ip='192.168.225.74'/>
      <host mac='52:54:02:54:00:75' ip='192.168.225.75'/>
      <host mac='52:54:02:54:00:76' ip='192.168.225.76'/>
      <host mac='52:54:02:54:00:77' ip='192.168.225.77'/>
      <host mac='52:54:02:54:00:78' ip='192.168.225.78'/>
      <host mac='52:54:02:54:00:79' ip='192.168.225.79'/>
      <host mac='52:54:02:54:00:80' ip='192.168.225.80'/>
      <host mac='52:54:02:54:00:81' ip='192.168.225.81'/>
      <host mac='52:54:02:54:00:82' ip='192.168.225.82'/>
      <host mac='52:54:02:54:00:83' ip='192.168.225.83'/>
      <host mac='52:54:02:54:00:84' ip='192.168.225.84'/>
      <host mac='52:54:02:54:00:85' ip='192.168.225.85'/>
      <host mac='52:54:02:54:00:86' ip='192.168.225.86'/>
      <host mac='52:54:02:54:00:87' ip='192.168.225.87'/>
      <host mac='52:54:02:54:00:88' ip='192.168.225.88'/>
      <host mac='52:54:02:54:00:89' ip='192.168.225.89'/>
      <host mac='52:54:02:54:00:90' ip='192.168.225.90'/>
      <host mac='52:54:02:54:00:91' ip='192.168.225.91'/>
      <host mac='52:54:02:54:00:92' ip='192.168.225.92'/>
      <host mac='52:54:02:54:00:93' ip='192.168.225.93'/>
      <host mac='52:54:02:54:00:94' ip='192.168.225.94'/>
      <host mac='52:54:02:54:00:95' ip='192.168.225.95'/>
      <host mac='52:54:02:54:00:96' ip='192.168.225.96'/>
      <host mac='52:54:02:54:00:97' ip='192.168.225.97'/>
      <host mac='52:54:02:54:00:98' ip='192.168.225.98'/>
      <host mac='52:54:02:54:00:99' ip='192.168.225.99'/>
      <host mac='52:54:02:54:01:00' ip='192.168.225.100'/>
      <host mac='52:54:02:54:01:01' ip='192.168.225.101'/>
      <host mac='52:54:02:54:01:02' ip='192.168.225.102'/>
      <host mac='52:54:02:54:01:03' ip='192.168.225.103'/>
      <host mac='52:54:02:54:01:04' ip='192.168.225.104'/>
      <host mac='52:54:02:54:01:05' ip='192.168.225.105'/>
      <host mac='52:54:02:54:01:06' ip='192.168.225.106'/>
      <host mac='52:54:02:54:01:07' ip='192.168.225.107'/>
      <host mac='52:54:02:54:01:08' ip='192.168.225.108'/>
      <host mac='52:54:02:54:01:09' ip='192.168.225.109'/>
      <host mac='52:54:02:54:01:10' ip='192.168.225.110'/>
      <host mac='52:54:02:54:01:11' ip='192.168.225.111'/>
      <host mac='52:54:02:54:01:12' ip='192.168.225.112'/>
      <host mac='52:54:02:54:01:13' ip='192.168.225.113'/>
      <host mac='52:54:02:54:01:14' ip='192.168.225.114'/>
      <host mac='52:54:02:54:01:15' ip='192.168.225.115'/>
      <host mac='52:54:02:54:01:16' ip='192.168.225.116'/>
      <host mac='52:54:02:54:01:17' ip='192.168.225.117'/>
      <host mac='52:54:02:54:01:18' ip='192.168.225.118'/>
      <host mac='52:54:02:54:01:19' ip='192.168.225.119'/>
      <host mac='52:54:02:54:01:20' ip='192.168.225.120'/>
      <host mac='52:54:02:54:01:21' ip='192.168.225.121'/>
      <host mac='52:54:02:54:01:22' ip='192.168.225.122'/>
      <host mac='52:54:02:54:01:23' ip='192.168.225.123'/>
      <host mac='52:54:02:54:01:24' ip='192.168.225.124'/>
      <host mac='52:54:02:54:01:25' ip='192.168.225.125'/>
      <host mac='52:54:02:54:01:26' ip='192.168.225.126'/>
      <host mac='52:54:02:54:01:27' ip='192.168.225.127'/>
      <host mac='52:54:02:54:01:28' ip='192.168.225.128'/>
      <host mac='52:54:02:54:01:29' ip='192.168.225.129'/>
      <host mac='52:54:02:54:01:30' ip='192.168.225.130'/>
      <host mac='52:54:02:54:01:31' ip='192.168.225.131'/>
      <host mac='52:54:02:54:01:32' ip='192.168.225.132'/>
      <host mac='52:54:02:54:01:33' ip='192.168.225.133'/>
      <host mac='52:54:02:54:01:34' ip='192.168.225.134'/>
      <host mac='52:54:02:54:01:35' ip='192.168.225.135'/>
      <host mac='52:54:02:54:01:36' ip='192.168.225.136'/>
      <host mac='52:54:02:54:01:37' ip='192.168.225.137'/>
      <host mac='52:54:02:54:01:38' ip='192.168.225.138'/>
      <host mac='52:54:02:54:01:39' ip='192.168.225.139'/>
      <host mac='52:54:02:54:01:40' ip='192.168.225.140'/>
      <host mac='52:54:02:54:01:41' ip='192.168.225.141'/>
      <host mac='52:54:02:54:01:42' ip='192.168.225.142'/>
      <host mac='52:54:02:54:01:43' ip='192.168.225.143'/>
      <host mac='52:54:02:54:01:44' ip='192.168.225.144'/>
      <host mac='52:54:02:54:01:45' ip='192.168.225.145'/>
      <host mac='52:54:02:54:01:46' ip='192.168.225.146'/>
      <host mac='52:54:02:54:01:47' ip='192.168.225.147'/>
      <host mac='52:54:02:54:01:48' ip='192.168.225.148'/>
      <host mac='52:54:02:54:01:49' ip='192.168.225.149'/>
      <host mac='52:54:02:54:01:50' ip='192.168.225.150'/>
      <host mac='52:54:02:54:01:51' ip='192.168.225.151'/>
      <host mac='52:54:02:54:01:52' ip='192.168.225.152'/>
      <host mac='52:54:02:54:01:53' ip='192.168.225.153'/>
      <host mac='52:54:02:54:01:54' ip='192.168.225.154'/>
      <host mac='52:54:02:54:01:55' ip='192.168.225.155'/>
      <host mac='52:54:02:54:01:56' ip='192.168.225.156'/>
      <host mac='52:54:02:54:01:57' ip='192.168.225.157'/>
      <host mac='52:54:02:54:01:58' ip='192.168.225.158'/>
      <host mac='52:54:02:54:01:59' ip='192.168.225.159'/>
      <host mac='52:54:02:54:01:60' ip='192.168.225.160'/>
      <host mac='52:54:02:54:01:61' ip='192.168.225.161'/>
      <host mac='52:54:02:54:01:62' ip='192.168.225.162'/>
      <host mac='52:54:02:54:01:63' ip='192.168.225.163'/>
      <host mac='52:54:02:54:01:64' ip='192.168.225.164'/>
      <host mac='52:54:02:54:01:65' ip='192.168.225.165'/>
      <host mac='52:54:02:54:01:66' ip='192.168.225.166'/>
      <host mac='52:54:02:54:01:67' ip='192.168.225.167'/>
      <host mac='52:54:02:54:01:68' ip='192.168.225.168'/>
      <host mac='52:54:02:54:01:69' ip='192.168.225.169'/>
      <host mac='52:54:02:54:01:70' ip='192.168.225.170'/>
      <host mac='52:54:02:54:01:71' ip='192.168.225.171'/>
      <host mac='52:54:02:54:01:72' ip='192.168.225.172'/>
      <host mac='52:54:02:54:01:73' ip='192.168.225.173'/>
      <host mac='52:54:02:54:01:74' ip='192.168.225.174'/>
      <host mac='52:54:02:54:01:75' ip='192.168.225.175'/>
      <host mac='52:54:02:54:01:76' ip='192.168.225.176'/>
      <host mac='52:54:02:54:01:77' ip='192.168.225.177'/>
      <host mac='52:54:02:54:01:78' ip='192.168.225.178'/>
      <host mac='52:54:02:54:01:79' ip='192.168.225.179'/>
      <host mac='52:54:02:54:01:80' ip='192.168.225.180'/>
      <host mac='52:54:02:54:01:81' ip='192.168.225.181'/>
      <host mac='52:54:02:54:01:82' ip='192.168.225.182'/>
      <host mac='52:54:02:54:01:83' ip='192.168.225.183'/>
      <host mac='52:54:02:54:01:84' ip='192.168.225.184'/>
      <host mac='52:54:02:54:01:85' ip='192.168.225.185'/>
      <host mac='52:54:02:54:01:86' ip='192.168.225.186'/>
      <host mac='52:54:02:54:01:87' ip='192.168.225.187'/>
      <host mac='52:54:02:54:01:88' ip='192.168.225.188'/>
      <host mac='52:54:02:54:01:89' ip='192.168.225.189'/>
      <host mac='52:54:02:54:01:90' ip='192.168.225.190'/>
      <host mac='52:54:02:54:01:91' ip='192.168.225.191'/>
      <host mac='52:54:02:54:01:92' ip='192.168.225.192'/>
      <host mac='52:54:02:54:01:93' ip='192.168.225.193'/>
      <host mac='52:54:02:54:01:94' ip='192.168.225.194'/>
      <host mac='52:54:02:54:01:95' ip='192.168.225.195'/>
      <host mac='52:54:02:54:01:96' ip='192.168.225.196'/>
      <host mac='52:54:02:54:01:97' ip='192.168.225.197'/>
      <host mac='52:54:02:54:01:98' ip='192.168.225.198'/>
      <host mac='52:54:02:54:01:99' ip='192.168.225.199'/>
    </dhcp>
  </ip>
</network>
EOF
```

Define, start and autostart lab Internet network and management network:

- lab-internet

```bash
virsh -c qemu:///system net-define lab-internet.xml
```

```bash
virsh -c qemu:///system net-start lab-internet
```

```bash
virsh -c qemu:///system net-autostart lab-internet
```

- vagrant-mgmt

```bash
virsh -c qemu:///system net-define vagrant-mgmt.xml
```

```bash
virsh -c qemu:///system net-start vagrant-mgmt
```

```bash
virsh -c qemu:///system net-autostart vagrant-mgmt
```

## Setup iptables

Block access from virbr225 and virbr10 to RFC1918 networks

```bash
sudo iptables -I FORWARD -i virbr225 -d 10.0.0.0/8 -j DROP
sudo iptables -I FORWARD -i virbr225 -d 172.16.0.0/12 -j DROP
sudo iptables -I FORWARD -i virbr225 -d 192.168.0.0/16 -j DROP
```

```bash
sudo iptables -I FORWARD -i virbr10 -d 10.0.0.0/8 -j DROP
sudo iptables -I FORWARD -i virbr10 -d 172.16.0.0/12 -j DROP
sudo iptables -I FORWARD -i virbr10 -d 192.168.0.0/16 -j DROP
```

Save rules

```bash
sudo netfilter-persistent save
```

## Install Guacamole

First [install docker compose](/resources/docs/install-docker-compose.md)

Clone the project

```
git clone https://github.com/celeroon/guacamole-docker-compose
```

Move into thje project directory

```
cd guacamole-docker-compose
```

Run the preparation script

```
./prepare.sh
```

Start Docker Compose

```
docker compose up -d
```

## Disable offload

Based on [virtio-net issue](https://github.com/virtio-win/kvm-guest-drivers-windows/issues/1131) the offloading disable is required, instead Windows VMs will have 2-5mbps download speed:

```
sudo ethtool -K <main_interface> rx off
sudo ethtool -K <main_interface> tx off
sudo ethtool -K <main_interface> tso off
sudo ethtool -K <main_interface> gso off
sudo ethtool -K <main_interface> gro off
sudo ethtool -K <main_interface> lro off
```

To automate offloading disabling by script - create it and enable service:

Define the main interface name variable (change `eno1` to match your network interface)

```
IFACE="eno1"
```

Generate the script

```
cat <<EOF | sudo tee /usr/local/bin/disable-offload.sh > /dev/null
#!/bin/bash
IFACE="$IFACE"

ethtool -K \$IFACE rx off
ethtool -K \$IFACE tx off
ethtool -K \$IFACE tso off
ethtool -K \$IFACE gso off
ethtool -K \$IFACE gro off
ethtool -K \$IFACE lro off
EOF
```

```
sudo chmod +x /usr/local/bin/disable-offload.sh
```

Create a systemd service

```
cat <<EOF | sudo tee /etc/systemd/system/disable-offload.service > /dev/null
[Unit]
Description=Disable NIC offloading features
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/disable-offload.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
```

Enable and start the service

```
sudo systemctl daemon-reexec
sudo systemctl enable disable-offload.service
sudo systemctl start disable-offload.service
```
