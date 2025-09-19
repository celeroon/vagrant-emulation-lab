# Setup ELK node

In this section, we will install Elasticsearch with Logstash and Kibana using Docker Compose. Later, I will add instructions on how to set up ELK without Docker, but that method will take much more time.

* [Install ELK with Docker Compose](#install-elk-with-docker-compose)

<!-- * [Install ELK manually] -->  

## Install ELK with Docker Compose

Run the VM:

```bash
vagrant up elk-1
```

Access the VM by name using `vagrant ssh` or via the management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

Next, you need to:

* [Configure networking](/resources/docs/setup-networking.md)
* [Install Docker with Docker Compose](/resources/docs/install-docker-compose.md)

Install the required packages:

```bash
sudo apt update && sudo apt install -y git curl jq
```

Clone the project repository and enter the project directory:

```bash
git clone https://github.com/celeroon/docker-compose-elastic-stack
cd docker-compose-elastic-stack
```

Create a new `.env` file. You can adjust some settings, for example increase memory usage, change the password, or set the latest available Elasticsearch version:

```bash
cat <<EOF | tee .env
STACK_VERSION=9.1.4

CLUSTER_NAME=lab-cluster

ELASTIC_PASSWORD=SuperSecret123$

ES_PORT=9200
KIBANA_PORT=5601
FLEET_PORT=8220
LOGSTASH_PORT=5145

CERT_PASS=PASSWORD
LICENSE=basic

# For VM with 16GB RAM
ES_MEM_LIMIT=10737418240   # 10 GB
KB_MEM_LIMIT=4294967296    # 4 GB
LS_MEM_LIMIT=1073741824    # 1 GB

XPACK_ENCRYPTEDSAVEDOBJECTS_ENCRYPTIONKEY=4b7c3ae892a7bcd357d01bfa64cc5d9d
XPACK_REPORTING_ENCRYPTIONKEY=155945c52ce5831295f3544cc4699983
XPACK_SECURITY_ENCRYPTIONKEY=ea54d0f815d0db318f2334e33c4730e9

FLEET_SERVER_HOST=172.16.10.5
ES_SERVER_HOST=172.16.10.5
EOF
```

Make all the scripts in the `custom-scripts` directory executable:

```bash
chmod +x custom-scripts/*
```

Build and run:

```bash
docker compose build
docker compose up -d
```
