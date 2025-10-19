# Setup Velociraptor

In this section we will setup Velociraptor Server to later add an Windows Agent.

Run VM

```bash
vagrant up velociraptor-1
```

Before accessing the Velociraptor VM, copy the server and client config:

```bash
scp -i ~/.vagrant.d/insecure_private_key ./ansible/artifacts/server.config.yaml vagrant@192.168.225.108:/home/vagrant
scp -i ~/.vagrant.d/insecure_private_key ./ansible/artifacts/client.config.yaml vagrant@192.168.225.108:/home/vagrant
scp -i ~/.vagrant.d/insecure_private_key ./ansible/artifacts/api.config.yaml vagrant@192.168.225.108:/home/vagrant
```

Or using `vagrant scp`:

```bash
vagrant scp ./ansible/artifacts/server.config.yaml velociraptor-1:/home/vagrant/
vagrant scp ./ansible/artifacts/client.config.yaml velociraptor-1:/home/vagrant/
vagrant scp ./ansible/artifacts/api.config.yaml velociraptor-1:/home/vagrant/
```

Access the VM by name using `vagrant ssh` or via the management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

Next, you need to [configure networking](/resources/docs/setup-networking.md)

Create velociraptor directory

```bash
sudo mkdir /opt/velociraptor/
```

Navigate to the Velociraptor working directory:

```bash
cd /opt/velociraptor/
```

Install required packages:

```bash
sudo apt update && sudo apt install curl python3-pip jq -y
```

Move server and client configuration files to the Velociraptor directory:

```bash
sudo mv /home/vagrant/server.config.yaml ./server.config.yaml
sudo mv /home/vagrant/client.config.yaml ./client.config.yaml
sudo mv /home/vagrant/api.config.yaml ./api.config.yaml
```

Download Velociraptor Linux binary:

```bash
sudo curl -L "https://github.com/Velocidex/velociraptor/releases/download/v0.74/velociraptor-v0.74.5-linux-amd64" -o /opt/velociraptor/velociraptor
```

Download Windows EXE (original):

```bash
sudo curl -L "https://github.com/Velocidex/velociraptor/releases/download/v0.74/velociraptor-v0.74.5-windows-amd64.exe" -o /opt/velociraptor/velociraptor-windows.exe
```

Make the binary executable:

```bash
sudo chmod +x ./velociraptor
```

Build the Velociraptor Debian package (server):

```bash
sudo ./velociraptor debian server --config ./server.config.yaml
```

Install the Velociraptor server package:

```bash
sudo dpkg -i ./velociraptor-server-0.74.5.amd64.deb
```

Repack the Velociraptor Windows EXE with the client config:

```bash
sudo ./velociraptor config repack --exe ./velociraptor-windows.exe ./client.config.yaml ./velociraptor.exe
```

Change Velociraptor Windows EXE file permissions so it can be downloaded:

```bash
sudo chown vagrant:vagrant /opt/velociraptor/velociraptor.exe
sudo chmod 0644 /opt/velociraptor/velociraptor.exe
```

Copy the repacked EXE to artifacts (run on the **main host**):

```bash
scp -i ~/.vagrant.d/insecure_private_key vagrant@192.168.225.108:/opt/velociraptor/velociraptor.exe ./ansible/artifacts/velociraptor.exe
```

Or using `vagrant scp`:

```bash
vagrant scp velociraptor-1:/opt/velociraptor/velociraptor.exe ./ansible/artifacts/velociraptor.exe
```

Install pyvelociraptor

```bash
pip3 install pyvelociraptor
```

Add ~/.local/bin to your PATH so you can run pyvelociraptor without specifying the full path:

```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

Verify

```bash
which pyvelociraptor
pyvelociraptor --help
```

Set ownership of `/opt/velociraptor` recursively (run on the Velociraptor node):

```bash
sudo chown -R velociraptor:velociraptor /opt/velociraptor
```

Restart the Velociraptor service (run on the Velociraptor node):

```bash
sudo systemctl restart velociraptor_server.service
```

Default usernames/passwords are preconfigured: `vagrant` / `vagrant`. Access Velociraptor at: `https://172.16.10.8:8889`

Reference:

- Create API config

```bash
velociraptor --config server.config.yaml config api_client --name vagrant --role api,administrator api.config.yaml
```
