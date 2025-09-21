# Setup DFIR-IRIS

In this section we will setup DFIR-IRIS to the further integration in workflows mainly for case management.

Run VM

```bash
vagrant up dfir-iris-1
```

Access the VM by name using `vagrant ssh` or via the management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

Next, you need to:

* [Configure networking](/resources/docs/setup-networking.md)
* [Install Docker with Docker Compose](/resources/docs/install-docker-compose.md)

Install required packages

```bash
sudo apt update && sudo apt install -y curl git jq
```

Clone IRIS web repo

```bash
sudo git clone --branch v2.4.20 https://github.com/dfir-iris/iris-web.git /opt/iris-web
```

Changes the ownership of the working directory

```bash
sudo chown -R "$USER":"$USER" /opt/iris-web
```

Navigate to the working directory

```bash
cd /opt/iris-web
```

Create `.env` file from a existed example

```bash
cp .env.model .env
```

In the `.env` file change Postgress passwords (make sure to change for your own)

```bash
sed -i \
  -e 's/^POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=vagrant/' \
  -e 's/^POSTGRES_ADMIN_PASSWORD=.*/POSTGRES_ADMIN_PASSWORD=vagrant/' \
  .env
```

For lab purpose I will also pre-define easy API key (make sure to change it)

```bash
echo 'IRIS_ADM_API_KEY=vagrant' >> /opt/iris-web/.env
```

Run docker compose

```bash
docker compose up -d
```

Wait for IRIS `Administrator` password to appear in logs (`You can now login with user administrator and password >>> <PASSWORD> <<< on 443`)

```bash
docker logs iriswebapp_app
```

This password is hard to memorize but in the lab environment we can change it to something easier. Based on the [official documentation](https://docs.dfir-iris.org/operations/access_control/authentication/) you need to generate hash first (replase `vagrant` with your own password)

```bash
import bcrypt
print(bcrypt.hashpw('vagrant'.encode('utf-8'), bcrypt.gensalt()))
```

Connect to DB and update password. Run those commands below (I will use predefined hash for `vagrant` password, make sure to change it)

```bash
docker exec -ti iriswebapp_db /bin/bash
```

```bash
su postgres
```

```bash
psql
```

```bash
\c iris_db 
```

```bash
UPDATE "user" SET password = '$2a$12$j4mjlZjKQ7Sd/Yb9MyBdFuVBNg2qLlWaNV9sdIhGEnjr6.FOW4qLO' WHERE "user".name = 'administrator';
```

```bash
\q
```

```bash
exit
```

```bash
exit
```

You will get access on `https://172.16.10.6` later on your Windows VM.
