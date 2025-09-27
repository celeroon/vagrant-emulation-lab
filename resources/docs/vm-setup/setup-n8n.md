# Setup n8n

In this section, we will set up only the VM. Later, when the Windows VM is available via Guacamole, you will be able to access the n8n GUI.

Run VM

```bash
vagrant up n8n-1
```

Access the VM by name using `vagrant ssh` or via the management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

Next, you need to:

* [Configure networking](/resources/docs/setup-networking.md)
* [Install Docker with Docker Compose](/resources/docs/install-docker-compose.md)

Install required packages

```bash
sudo apt update && sudo apt install -y curl git openssl python3-cryptography
```

Create working and certificate directories and set ownership

```bash
sudo install -d -m 0755 /opt/n8n-compose/certs
sudo chown 1000:1000 /opt/n8n-compose/certs
```

Generate a private key for the local CA

```bash
sudo openssl genrsa -out /opt/n8n-compose/certs/ca.key 4096
```

Create a self-signed root CA certificate

```bash
sudo openssl req -x509 -new -sha256 -days 1825 \
  -key /opt/n8n-compose/certs/ca.key \
  -out /opt/n8n-compose/certs/ca.crt \
  -subj "/CN=Vlad Lab Local CA"
```

Generate a private key for the n8n server

```bash
sudo openssl genrsa -out /opt/n8n-compose/certs/n8n.key 4096
```

Create a CSR with CN and SAN set to 172.16.10.7

```bash
sudo openssl req -new \
  -key /opt/n8n-compose/certs/n8n.key \
  -out /opt/n8n-compose/certs/n8n.csr \
  -subj "/CN=172.16.10.7" \
  -addext "subjectAltName=IP:172.16.10.7"
```

Define certificate extensions

```bash
cat <<'EOF' | sudo tee /opt/n8n-compose/certs/v3.ext >/dev/null
basicConstraints=CA:FALSE
keyUsage=digitalSignature,keyEncipherment
extendedKeyUsage=serverAuth
subjectAltName=IP:172.16.10.7
EOF
```

Sign the server CSR with the local CA to generate a valid TLS certificate

```bash
sudo openssl x509 -req -sha256 -days 825 \
  -in /opt/n8n-compose/certs/n8n.csr \
  -CA /opt/n8n-compose/certs/ca.crt \
  -CAkey /opt/n8n-compose/certs/ca.key \
  -CAcreateserial \
  -out /opt/n8n-compose/certs/n8n.crt \
  -extfile /opt/n8n-compose/certs/v3.ext
```

Set secure permissions for key and cert files

```bash
sudo chmod 600 /opt/n8n-compose/certs/n8n.key
sudo chmod 644 /opt/n8n-compose/certs/n8n.crt /opt/n8n-compose/certs/ca.crt
sudo chown 1000:1000 /opt/n8n-compose/certs/*
```

Create docker-compose.yml file

```bash
cat <<EOF | sudo tee /opt/n8n-compose/docker-compose.yml > /dev/null
services:
  n8n:
    image: docker.n8n.io/n8nio/n8n
    container_name: n8n
    user: "1000:1000"
    restart: always
    ports:
      - "443:443"
    environment:
      - N8N_HOST=172.16.10.7
      - N8N_PORT=443
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://172.16.10.7/
      - N8N_SSL_CERT=/certs/n8n.crt
      - N8N_SSL_KEY=/certs/n8n.key
      - N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true
    volumes:
      - n8n_data:/home/node/.n8n
      - /opt/n8n-compose/certs:/certs:ro

volumes:
  n8n_data:
EOF
```

Start n8n docker compose 

```bash
sudo docker compose -f /opt/n8n-compose/docker-compose.yml up -d
```

Further configuration will be done from Windows VM.

In future n8n workflows we will generate PDF reports. To prepare for this, in the initial setup stage we need to install [gotenberg](https://gotenberg.dev/).

Create and enter a new directory:

```bash
mkdir ~/gotenberg && cd ~/gotenberg
```

Create a Docker Compose file:

```bash
tee "./docker-compose.yml" > /dev/null <<'EOF'
services:
  gotenberg:
    image: gotenberg/gotenberg:8
    container_name: gotenberg
    ports:
      - "3000:3000"
    restart: always
EOF
```

Start the Gotenberg container:

```bash
docker compose up -d
```
