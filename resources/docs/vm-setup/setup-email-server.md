# Setup Email Server

In this section I’ll show how to set up an email server where you can generate local emails using a Python script (to emulate phishing).

Run the VM:

```bash
vagrant up email-server-1
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
  address 192.168.225.2
  netmask 255.255.255.0
  pre-up sleep 2

auto eth1
iface eth1 inet static
  address 203.0.113.6
  netmask 255.255.255.248
  gateway 203.0.113.1
  dns-nameservers 8.8.8.8
  pre-up sleep 2
EOF
```

Restart networking:

```bash
sudo systemctl restart networking
```

Next, create a working directory for the mail server (this will be your working directory on the VM):

```bash
mkdir ~/lab-email-server
cd ~/lab-email-server
```

Save configuration files (from the gist links):

```bash
curl -O https://gist.githubusercontent.com/celeroon/47b7f7d75ba84641be8ce2ef6a5e1b8e/raw/945801cd49de758b6b09b094a64bdc8ee99a18fa/90-quota.conf
curl -O https://gist.githubusercontent.com/celeroon/2eb88b0d075c8e6585f95ea68d2eae57/raw/879e6304f98f2c182a2860ea9d32ca45aa4ff1a0/.env
curl -O https://gist.githubusercontent.com/celeroon/9e2519873c15bb55404f47aef34d52f0/raw/5b485345589a5981d3754de46aa44dd4e2658c1d/main.cf
curl -O https://gist.githubusercontent.com/celeroon/8a166092a3f078a52e98972992d4fbca/raw/ae034c3769632197cba5125af37e305072976bfa/docker-compose.yml
curl -O https://gist.githubusercontent.com/celeroon/ae120b1181289e6e006896270f4810b6/raw/57523b301431979f54f7ab0a1e5a9f5952508a42/openssl.cnf
curl -O https://gist.githubusercontent.com/celeroon/d35815659a6263eae5b23e6876ffcbe7/raw/2f19df46a324908ce0de8dcace6336d433305690/nginx.conf
curl -O https://gist.githubusercontent.com/celeroon/37432b441b9e14a2627039038a31f9f8/raw/6ea75d421c492d2cf01a05910e8972a4ba8d8cba/master.cf
curl -O https://gist.githubusercontent.com/celeroon/9ab7679a76fcf67016dfb1bfaecd72ff/raw/a27264803b9e068f64f6e49c04344d45a6f2fc3d/send_test_emails.py
```

Create required directories:

```bash
mkdir -p ~/docker/mailserver/{data,state,logs,config}
mkdir -p ~/docker/roundcube/{config,logs,db}
mkdir -p /tmp/docker-mailserver/config
```

Install helper packages:

```bash
sudo apt update && sudo apt install -y zip unzip telnet git
```

Install Docker:

```bash
sudo curl -fsSL https://get.docker.com -o ./get-docker.sh
sudo chmod 755 ./get-docker.sh
sudo sh ./get-docker.sh
```

Get latest Docker Compose release tag and download the binary:

```bash
docker_compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
sudo curl -L "https://github.com/docker/compose/releases/download/${docker_compose_version}/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
sudo chmod 755 /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
```

Add current user to the docker group:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

If using a Debian VM from Vagrant Cloud, port 25 may be used by the local postfix service — stop/disable it:

```bash
ss -tulpn | grep ':25'
sudo systemctl stop postfix
sudo systemctl disable postfix
```

Create a mail user and generate a password hash (check `.env` to change default password):

```bash
docker run --rm --env-file .env -it mailserver/docker-mailserver \
    /bin/sh -c 'echo "$MAIL_USER|$(doveadm pw -s SHA512-CRYPT -u $MAIL_USER -p $MAIL_PASS)"' \
    >> ~/docker/mailserver/config/postfix-accounts.cf
```

Prepare SSL cert directory for Roundcube:

```bash
mkdir -p ~/docker/roundcube/config/certs
cp openssl.cnf ~/docker/roundcube/config/certs/openssl.cnf
```

Generate self-signed certificates (lab use):

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ~/docker/roundcube/config/certs/privkey.pem \
    -out ~/docker/roundcube/config/certs/fullchain.pem \
    -config ~/docker/roundcube/config/certs/openssl.cnf
```

Set permissions on the cert folder:

```bash
sudo chown root:root ~/docker/roundcube/config/certs
sudo chmod 755 ~/docker/roundcube/config/certs
```

Start the mail stack:

```bash
docker-compose up -d
```

Wait for the mail server to be ready (check logs periodically):

```bash
docker logs mailserver 2>&1 | grep 'is up and running'
```

Check container status:

```bash
container_status=$(docker ps -a --filter "name=mailserver" --format "{{.Status}}")
echo "Mailserver container status: $container_status"

# or
docker ps -a --filter "name=mailserver" | grep "Up"
```

Create a sample attachment:

```bash
echo "This is a test file" >> test.txt
zip attachment.zip test.txt
```

Send test emails:

```bash
python3 send_test_emails.py
```

You can return to this section and experiment with attachments — the lab email server configuration does not restrict attachments like `.exe` or `.zip` by default.
