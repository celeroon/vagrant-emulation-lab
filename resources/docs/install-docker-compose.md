
Install Docker

```bash
curl -fsSl https://get.docker.com -o get-docker.sh
```

```bash
sh get-docker.sh
```

Get the latest Docker Compose release version number from GitHub API

```bash
VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f4)
```

Download the Docker Compose binary

```bash
sudo curl -SL https://github.com/docker/compose/releases/download/${VERSION}/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
```

Make the Docker Compose binary executable

```bash
sudo chmod +x /usr/local/bin/docker-compose
```

Create a symbolic link so 'docker-compose' is accessible system-wide

```bash
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
```

Add current user to the 'docker' group

```bash
sudo usermod -aG docker $USER
```

Refresh user session

```bash
su - <USERNAME>
```

or using newgrp

```bash
newgrp docker
```
