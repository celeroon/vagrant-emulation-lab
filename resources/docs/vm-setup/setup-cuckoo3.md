# Setup Cuckoo3 Sandbox

In this section I want to show you how to set up [Cuckoo3 sandbox](https://github.com/cert-ee/cuckoo3). As on official documentation notices it is not for production deployment, and I also want to illustrate how to deploy sandbox in the lab environment. Previous deploy of CAPEv2 sandbox requires a lot of time also to setup Windows VM inside sandbox and my guideline is not complete and from another side the Cuckoo3 provides auto setup script, but I found some issues after setup and I found solutions that can be applied only in the lab environment for test. 

> [!IMPORTANT]  
> Before running the VM, make sure to edit the [configuration](/vms/linux/cuckoo3/config.rb) file with the appropriate CPU and RAM amounts based on your environment.

Run base VM

```bash
vagrant up cuckoo3-1
```

Access the VM by name using `vagrant ssh` or via the management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

Configure networking

```bash
sudo tee /etc/netplan/01-interfaces.yaml > /dev/null <<'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      addresses: [192.168.225.103/24]
      dhcp4: false
      dhcp6: false
    eth1:
      addresses: [172.16.10.3/24]
      routes:
        - to: 0.0.0.0/0
          via: 172.16.10.254
      nameservers:
        addresses: [8.8.8.8]
      dhcp4: false
      dhcp6: false
EOF
```

Apply the changes

```bash
sudo netplan apply
```

Updates and upgrades system packages

```bash
sudo apt update && sudo apt upgrade -y
```

Add attached `/dev/vdb` disk to existing LVM:

- Check already created LVM (get a volume name)

```bash
sudo pvs
```

- Create a physical volume on the new disk

```bash
sudo pvcreate /dev/vdb
```

- Verify

```bash
sudo pvs
```

- Extend your volume group to include the new disk

```bash
sudo vgextend ubuntu-vg /dev/vdb
```

- Check

```bash
sudo vgs
```

- Extend the logical volume (root filesystem)

```bash
sudo lvextend -r -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
```

Confirm the resizing

```bash
df -h && sudo lvs
```

Run cuckoo3 quicksetup script 

> [!IMPORTANT]  
> It will ask to create a new user with a password and Django app path. 
> I tested that quick installation works fine when you submit `cuckoo`/`cuckoo` as login and password

```bash
curl -sSf https://cuckoo-hatch.cert.ee/static/install/quickstart | sudo bash
```

The installation can take a while especially for Windows VM creation. You can diagnose Windows VM installation by creating SSH tunnel from a host to vagrant VM that runs Windows VM inside.

```bash
ssh -L 5901:127.0.0.1:5901 vagrant@192.168.225.103
```

<div align="center">
    <img alt="Cuckoo3 VMCloak" src="/resources/images/cuckoo3/vmcloak.png" width="100%">
</div>

Wait until install, you will see web server debug mode running, you can escape by pressing CTRL+C and reboot VM

```
2025-10-15 18:53:52 INFO  [cuckoo.startup]: Starting Cuckoo. cwd=/home/cuckoo/.cuckoocwd
2025-10-15 18:53:52 INFO  [cuckoo.startup]: Loading configurations
2025-10-15 18:53:53 INFO  [cuckoo.node.resultserver]: Changed maximum file descriptors to hard limit for current process. newmax=1048576
2025-10-15 18:53:53 INFO  [cuckoo.node.resultserver]: Started resultserver. listen_ip=192.168.30.1 listen_port=2042
2025-10-15 18:53:53 INFO  [cuckoo.node.machinery]: Loaded analysis machines. amount=3
2025-10-15 18:53:54 INFO  [cuckoo.runprocessing]: Starting identification worker. workername=identification0
2025-10-15 18:53:54 INFO  [cuckoo.runprocessing]: Starting pre worker. workername=pre0
2025-10-15 18:53:54 INFO  [cuckoo.runprocessing]: Starting post worker. workername=post0
2025-10-15 18:53:58 INFO  [cuckoo.scheduler]: Scheduler started
```

```bash
sudo reboot now
```

Create a new service to run cuckoo when VM starts

```bash
sudo tee /etc/systemd/system/cuckoo.service <<'EOF'
[Unit]
Description=Cuckoo Sandbox Core
Wants=network-online.target
After=network-online.target

[Service]
Type=simple
User=cuckoo
Group=cuckoo
WorkingDirectory=/home/cuckoo/.cuckoocwd
Environment=CUCKOO_CWD=/home/cuckoo/.cuckoocwd
# raise file limits (matches what debug run did)
LimitNOFILE=1048576
ExecStart=/home/cuckoo/cuckoo3/venv/bin/cuckoo
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
```

Enable service

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now cuckoo
```

Set up a helper script to run each time after restart (it will create br0 interface)

```bash
sudo mkdir -p /usr/local/share/cuckoo
sudo cp /home/vagrant/helper_script.sh /usr/local/share/cuckoo/helper_script.sh
sudo chmod 755 /usr/local/share/cuckoo/helper_script.sh
sudo chown root:root /usr/local/share/cuckoo/helper_script.sh
```

Make it run automatically at boot

```bash
sudo tee /etc/systemd/system/cuckoo-helper.service >/dev/null <<'EOF'
[Unit]
Description=Run Cuckoo helper script (bridge setup, etc.)
Wants=network-online.target
Before=cuckoo.service
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash -eux /usr/local/share/cuckoo/helper_script.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
```

Enable the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now cuckoo-helper
```

Create a new service to run Cuckoo API on startup

```bash
sudo tee /etc/systemd/system/cuckoo-api.service >/dev/null <<'EOF'
[Unit]
Description=Cuckoo Web API (development server)
Wants=network-online.target
After=network-online.target cuckoo.service

[Service]
Type=simple
User=cuckoo
Group=cuckoo
WorkingDirectory=/home/cuckoo/.cuckoocwd
ExecStart=/home/cuckoo/cuckoo3/venv/bin/cuckoo --cwd /home/cuckoo/.cuckoocwd api --host 0.0.0.0 --port 8090
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
```

Enable the service

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now cuckoo-api
```

Follow the instructions to generate API key

- Apply DB migrations. Run as the cuckoo user so file ownerships and $CWD match:

```bash
sudo -u cuckoo /home/cuckoo/cuckoo3/venv/bin/cuckoo --cwd /home/cuckoo/.cuckoocwd api djangocommand migrate
```

- Create and save an API key

```bash
sudo -u cuckoo /home/cuckoo/cuckoo3/venv/bin/cuckoo --cwd /home/cuckoo/.cuckoocwd api token --create "admin"
```

- List tokens:

```bash
sudo -u cuckoo /home/cuckoo/cuckoo3/venv/bin/cuckoo --cwd /home/cuckoo/.cuckoocwd api token --list
```

- Start the dev (test) API server

```bash
sudo -u cuckoo /home/cuckoo/cuckoo3/venv/bin/cuckoo --cwd /home/cuckoo/.cuckoocwd api --host 0.0.0.0 --port 9080 &
```

- Check it is listening

```bash
ss -ltnp | egrep ':(8090|9080|9090)\b'
```

Now the Cuckoo3 is configured. Some API examples will be shown in later n8n workflows. You can access instance from lab Windows Workstation VM on `http://172.16.10.3` or from Ubuntu VM (vagrant box) manage interface - `http://192.168.225.103`.
