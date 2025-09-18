# Setup ELK node

In this section we will install Elasticsearch with Logstash and Kibana using Docker Compose. Later in this section I will add instructions how to setup ELK without docker, but it will take way more time. 

* [Install ELK with Docker Compose](#install-elk-with-docker-compose)
<!-- * [Install ELK manually] -->

## Install ELK with Docker Compose

Run VM

```bash
vagrant up elk-1
```

Access VM by name using `vagrant ssh` or via management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg)

Next you neeed to:

* [Configure networking](/resources/docs/setup-networking.md)
* [Install docker with docker compose](/resources/docs/install-docker-compose.md)

Install required packages

```bash
sudo apt update && sudo apt install -y git curl jq
```

Clone project repository and enter project directory

```bash
git clone https://github.com/celeroon/docker-compose-elastic-stack
cd docker-compose-elastic-stack
```

Create new .env file. Some settings you can change, for example you can increase memory usage

```bash
cat <<EOF | tee .env
STACK_VERSION={{ elk_version }}

CLUSTER_NAME=lab-cluster

ELASTIC_PASSWORD={{ elk_password }}

ES_PORT=9200
KIBANA_PORT=5601
FLEET_PORT=8220
LOGSTASH_PORT=9001
NETFLOW_PORT=9011

CERT_PASS=PASSWORD
LICENSE=basic

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

