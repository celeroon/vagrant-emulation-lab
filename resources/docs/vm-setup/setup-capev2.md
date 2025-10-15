# Setup CAPEv2 node

> [!CAUTION]
> This guide is not complete due to the lack of reliable deployment instructions. The described setup may not work properly. I will revisit and update this installation process in the future.

In this section, we will create a CAPEv2 instance in the lab. This setup will probably be manual only, as it is difficult to configure with automation scripts, especially when disabling all unnecessary services on Windows. The official documentation recommends using Windows 10 21H2, but we will use a Windows 10 box from Vagrant Cloud (22H2). This setup is for lab use only; to run it in production, you need to properly configure the VM, for example, to avoid virtualization detection. The following tools may be useful:

* [https://github.com/a0rtega/pafish](https://github.com/a0rtega/pafish)
* [https://github.com/ayoubfaouzi/al-khaser](https://github.com/ayoubfaouzi/al-khaser)

You can find the official recommendations in the repository:
[Installation recommendations and scripts for optimal performance](https://github.com/kevoreilly/CAPEv2?tab=readme-ov-file#installation-recommendations-and-scripts-for-optimal-performance)

I followed the instructions described in Rizqi Setyo Kusprihantanto’s blog posts:

* [https://osintteam.blog/building-capev2-automated-malware-analysis-sandbox-part-1-da2a6ff69cdb](https://osintteam.blog/building-capev2-automated-malware-analysis-sandbox-part-1-da2a6ff69cdb)
* [https://infosecwriteups.com/building-capev2-automated-malware-analysis-sandbox-part-2-0c47e4b5cbcd](https://infosecwriteupsudo chown cape:cape /opt/CAPEv2/conf/cuckoo.confs.com/building-capev2-automated-malware-analysis-sandbox-part-2-0c47e4b5cbcd)
* [https://osintteam.blog/building-capev2-automated-malware-analysis-sandbox-part-3-d5535a0ab6f6](https://osintteam.blog/building-capev2-automated-malware-analysis-sandbox-part-3-d5535a0ab6f6)

> [!IMPORTANT]  
> Before running the VM, make sure to edit the [configuration](/vms/linux/capev2/config.rb) file with the appropriate CPU and RAM amounts based on your environment.

Run base VM

```bash
vagrant up capev2-1
```

Access the VM by name using `vagrant ssh` or via the management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

Configure networking

```bash
sudo tee /etc/netplan/01-interfaces.yaml > /dev/null <<'EOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    ens7:
      addresses: [192.168.225.104/24]
      dhcp4: false
      dhcp6: false
    ens8:
      addresses: [172.16.10.4/24]
      routes:
        - to: 0.0.0.0/0
          via: 172.16.10.254
      nameservers:
        addresses: [8.8.8.8]
      dhcp4: false
      dhcp6: false
EOF
```

Apply changes

```bash
sudo netplan apply
```

Update and install the required tools:

```bash
sudo apt update && sudo apt upgrade -y
```

<!-- ```bash
sudo apt install git acpica-tools libxml2 libxml2-dev libxslt1-dev python3-libxml2 libgtk-vnc-2.0-dev gir1.2-gtk-vnc-2.0 gir1.2-gtksource-4 libgtksourceview-4-0 libgtksourceview-4-common python3-gi-cairo gir1.2-vte-2.90 libosinfo-1.0 python3-libvirt python3-requests graphviz graphviz-dev libvirt-dev parted -y
``` -->

```bash
sudo apt install git -y
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

Clone the project repository

```bash
git clone https://github.com/kevoreilly/CAPEv2.git "$HOME/CAPEv2"
```

You can use the `acpidump` tool to get the DSDT code, but I will use the same one as in the tutorial for Dell Inspiron 5566 (https://github.com/linuxhw/ACPI).

```bash
sed -i 's/<WOOT>/CBX3/g' $HOME/CAPEv2/installer/kvm-qemu.sh
```

Run KVM installer

```bash
chmod a+x $HOME/CAPEv2/installer/kvm-qemu.sh
```

```bash
sudo $HOME/CAPEv2/installer/kvm-qemu.sh all cape 2>&1 | tee ./$HOME/CAPEv2/installer/kvm-qemu.log
```

```bash
sudo $HOME/CAPEv2/installer/kvm-qemu.sh virtmanager cape 2>&1 | tee $HOME/CAPEv2/installer/kvm-qemu-virtmanager.log
```

Reboot VM

```bash
sudo reboot now
```

Edit the CAPEv2 installation script with the created network interface, network, and database password (you can change it).

```bash
sed -i \
  -e 's/^NETWORK_IFACE=.*/NETWORK_IFACE=virbr0/' \
  -e 's/^\(IFACE_IP=\).*/\1"192.168.122.1"/' \
  -e 's/^PASSWD=.*/PASSWD="vagrant"/' \
  $HOME/CAPEv2/installer/cape2.sh
```

Run installation script

```bash
chmod a+x $HOME/CAPEv2/installer/cape2.sh
```

```bash
sudo $HOME/CAPEv2/installer/cape2.sh base 2>&1 | tee $HOME/CAPEv2/installer/cape2-base.log
```

Reboot VM

```bash
sudo reboot now
```

Install additional features

```bash
poetry --directory /opt/CAPEv2 run pip3 install -r extra/optional_dependencies.txt
```

```bash
poetry --directory /opt/CAPEv2 run pip3 install chepy
```

```bash
sudo apt install graphviz graphviz-dev -y
```

Add DHCP reservation for Windows 10 VM

```bash
sudo EDITOR=nano virsh net-edit default
```

Add line right after `range` in `dhcp` section

```bash
<host mac='52:54:00:aa:bb:cc' ip='192.168.122.250'/>
```

<div align="center">
    <img alt="DHCP reservation" src="/resources/images/capev2/dhcp-reservation.png" width="100%">
</div>

Restart the network:

```bash
sudo virsh net-destroy default
```

```bash
sudo virsh net-start default
```

You should now see your static DHCP mapping

```bash
sudo virsh net-dumpxml default | grep host
```

Make sure the host can forward packets:

```bash
echo 1 | sudo tee /proc/sys/net/ipv4/ip_forward
sudo sysctl -w net.ipv4.ip_forward=1
```

To make it permanent (optional):

```bash
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sudo sysctl -p
```

Add DNAT rules (simple port forwarding)

- Do DNAT for incoming traffic from the external interface (ens7) and forward it to the Windows VM (192.168.122.250)

```bash
sudo iptables -t nat -I PREROUTING 1 -i ens7 -p tcp --dport 5986 -j DNAT --to-destination 192.168.122.250:5986
```

```bash
sudo iptables -t nat -I PREROUTING 1 -i ens7 -p tcp --dport 3389 -j DNAT --to-destination 192.168.122.250:3389
```

- Allow forwarding in both directions

```bash
sudo iptables -I FORWARD 1 -i ens7  -o virbr0 -p tcp -d 192.168.122.250 --dport 5986 -j ACCEPT
```

```bash
sudo iptables -I FORWARD 1 -i ens7  -o virbr0 -p tcp -d 192.168.122.250 --dport 3389 -j ACCEPT
```

```bash
sudo iptables -I FORWARD 1 -i virbr0 -o ens7  -p tcp -s 192.168.122.250 --sport 5986 -m state --state ESTABLISHED,RELATED -j ACCEPT
```

```bash
sudo iptables -I FORWARD 1 -i virbr0 -o ens7  -p tcp -s 192.168.122.250 --sport 3389 -m state --state ESTABLISHED,RELATED -j ACCEPT
```

(Optional) Make rules persistent

```bash
sudo apt install iptables-persistent -y
sudo netfilter-persistent save
```

Move back to the main host project directory and run the Windows 10 sandbox VM. If you changed the topology management addressing, make sure to edit the [Vagrantfile](/vms/linux/capev2/windows-sandobx/Vagrantfile)

```bash
VAGRANT_CWD=$HOME/vagrant-manual-lab/vms/linux/capev2/windows-sandobx/ vagrant up
```

It may take a while for Windows 10 to start up. While waiting for Vagrant to finish the job, you can already access the VM via VNC. Open **Remote Viewer** and provide the protocol, IP address, and port to connect: `vnc://192.168.225.104:5999`.

Instead of VNC, you can use RDP based on the forwarded ports we configured. Use the `remmina` or `freerdp2-x11` tool to access the Windows VM. Use the Ubuntu VM’s IP address, as the ports are forwarded:

```bash
xfreerdp /u:Administrator /v:192.168.225.104 /monitors:0 /multimon /port:3389
```

Based on the information provided on original [blog post](https://infosecwriteups.com/building-capev2-automated-malware-analysis-sandbox-part-2-0c47e4b5cbcd) - you need to disable Windows Defender and two repositories are provided:

* [ionuttbara](https://github.com/ionuttbara/windows-defender-remover)
* [es3n1n](https://github.com/es3n1n/no-defender)

On provided instructions you need to disable manually `Real-time protection` and `Tamper Protection`. I will use first repository where the packaged script is available in the project releases. You can simply run the `.exe` by following instructions and **restart** VM.

Following the guideline from blog post you need to disable window Update. There are several tools provided:

* [win10_disabler.ps1 from CAPEv2 repository](https://github.com/kevoreilly/CAPEv2/blob/master/installer/win10_disabler.ps1)
* [window-update-disabler](https://github.com/tsgrgo/window-update-disabler)

Add a bypass to execute PowerShell scripts:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Then unblock it

```powershell
Unblock-File .\win10_disabler.ps1
```

**Reboot VM**

Author also show additional tool [WereDev/Wu10Man](https://github.com/WereDev/Wu10Man) where describe what you need to disable inside app:

* All Schedules Tasks 
* All window Services

**Reboot VM**

And also shown [Winaero Tweaker](https://winaero.com/winaero-tweaker/) tool to disable additional features as:

* Ads and Unwanted Apps (check all except `stop unwanted apps that window installs automatically`)
* Disable Downloads Blocking (uncheck)
* Disable Driver Updates (check)
* Disable MRT From Installing (check)
* Disable SmartScreen (check all)
* Disable window Update (check)
* Disable window Defender (check)
* Protection Against Unwanted Software (uncheck)
* Auto-update Store apps (check)
* Disable Cortana (check)
* Disable Telemetry (check)

**Reboot VM**

another tools that must be disabled are Terminal Server, RDP-TCP, LSA, and Security System. Using `regedit.exe` you need to edit:

* `Computer\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server` -> fDenyTSConnections -> (hex) 0
* `Computer\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations` -> UserAuthentication -> (hex) 0
* `Computer\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Lsa` -> LimitBlankPasswordUse -> (hex) 0

<!-- Microsoft Office -->

Tweaking the Internet Options

Following the [blog post](https://infosecwriteups.com/building-capev2-automated-malware-analysis-sandbox-part-2-0c47e4b5cbcd) you need navigate to the `Control Panel` -> `Internet Options` and in the `Security` for each Internet, Local internet, Trusted sites, and Restricted sites zone - change properties as below:

<div align="center">
    <img alt="Internet properties" src="/resources/images/capev2/internet-properties.png" width="100%">
</div>

**.NET Framework**
- All enabled

**.NET Framework-reliant components**
- Permission for components with manifest - Disabled
- Other options are enabled

**ActiveX controls and plug-ins**
- Allow ActiveX Filtering - Disabled 
- Automatic prompting for ActiveX controls - Disabled
- Only allow approved domains to use ActiveX without prompt - Disabled
- Run antimalware software on Active controls - Disabled
- Other options are enabled

**Downloads**
- All enabled

**Enable .NET Framework Setup**
- Enabled

**Miscellaneous**
- Use Pop-up Blocker - Disabled
- Use window Defender SmartScreen - Disabled
- Other options are enabled

**Scripting**
- Enable XSS filter - Disabled
- Other options are enabled

**User Authentication**
- Logon - Anonymous logon

Next, navigate to the `Control Panel -> Internet Options -> Privacy` andu uncheck `Turn on Pop-up Blocker`. In the same window, above Pop-up Blocker sections you will see `Settings` click the `Advanced` and select `Accept` for `First-party` and `Third-party` Cookies.

At the top of the same window go to `Advanced` and scroll to the `Security` section and enable first 3 options:

- Allow active content from CDs...
- Allow active content to run ...
- Allow software to run ...

Install Python 3.10.6 (32-bit)

> [!IMPORTANT]  
> Make sure to select **Add Python 3.10. to PATH**

```powershell
wget https://www.python.org/ftp/python/3.10.6/python-3.10.6.exe -o python-3.10.6.exe
```

Install Pip and Pillow:

```powershell
python -m pip install --upgrade pip
```

```powershell
python -m pip install Pillow==9.5.0
```

Download the CAPEv2 agent

```powershell
wget https://raw.githubusercontent.com/kevoreilly/CAPEv2/master/agent/agent.py -o pizza.pyw
```

Install the agent by creating Task Scheduler described in official [guide](https://capev2.readthedocs.io/en/latest/installation/guest/agent.html)

You can change IP address configuration to static, but it can be DHCP also, because we have IP reservation on Ubuntu. Before moving next you need relogin or reboot window VM.

To test connectivity to window VM, go to the Ubuntu VM and run curl command to test connectivity to agent

```bash
curl 192.168.122.250:8000
```

You will get this message

```
{"message": "CAPE Agent!", "version": "0.20", "features": ["execpy", "execute", "pinning", "logs", "largefile", "unicodepath", "mutex", "browser_extension"], "is_user_admin": true}
```

To enable Multicast Name Resolution and Restrict Internet Communication you need to use `gpedit.msc` and enable them, navigate to:

* `Computer Configuration -> Administrative Template -> Network -> DNS Client -> Turn off multicast name resolution` - set `Enable`
* `Computer Configuration -> Administrative Template -> System -> Internet Communication Management -> Restrict Internet communication` - set Enable

Set ExecutionPolicy in the Unrestricted condition

```powershell
Set-ExecutionPolicy Unrestricted
```

If error appears that will told that already changes applied, I found this as a solution to execute
sudo chown cape:cape /opt/CAPEv2/conf/cuckoo.conf

Enter the Sysmon downloaded directory and install Sysmon

```powershell
.\Sysmon64.exe -i .\sysmonconfig.xml -accepteula
```

You can verify that Sysmon is installed and running using command `Get-Service -Name Sysmon*` and `sysmon64.exe -c` in powershell to see that sysmon configuration is applied.

At the end of setup window VM you can install common software to make window more realistic. After all make sure to close all program window. On a main host by using the Cockpit or Virtual Machine Manager navigate to the CAPEv2 (Ubuntu) VM and inside this VM open Virtual Machine Manager to create a snapshot.

> [!IMPORTANT]  
> window VM sandbox should be in the running state. From Virtual Machine Manage VM must be unlocked.

`View -> Snapshots -> (green plus) Create New Snapshot -> Enter name -> Finish`

<div align="center">
    <img alt="window sandbox snapshot" src="/resources/images/capev2/window-sandbox-snapshot.png" width="100%">
</div>

Create custom partitions to speed up memory analysis. This feature is optional in CAPEv2. New partition requires the allocation of storage size depends on the free space in the system.

```bash
sudo su
```

```bash
mkdir /mnt/tmpfs
```

```bash
mount -t tmpfs -o size=20g ramfs /mnt/tmpfs
```

```bash
chown cape:cape /mnt/tmpfs
```

```bash
nano /etc/fstab
```

Add a new entry at the end for the tmpfs mount

```bash
ramfs   /mnt/tmpfs   tmpfs   size=20g   0   0
```

Save and exit. Run the following to check that the syntax is correct and mount it

```bash
sudo mount -a
```

Verify it is mounted

```bash
df -h | grep /mnt/tmpfs
```

```bash
crontab -e
```

Just add at the end

```bash
@reboot chown cape:cape /mnt/tmpfs -R
```

Now we need edit some parameters in the CAPEv2 configuration files and run the service. 

**auxiliary.conf**

```bash
sudo sed -i \
  -e 's/^amsi = no/amsi = yes/' \
  -e 's/^curtain = no/curtain = yes/' \
  -e 's/^evtx = no/evtx = yes/' \
  -e 's/^human_linux = no/human_linux = yes/' \
  -e 's/^procmon = no/procmon = yes/' \
  -e 's/^recentfiles = no/recentfiles = yes/' \
  -e 's/^sysmon_windows = no/sysmon_windows = yes/' \
  -e 's/^usage = no/usage = yes/' \
  -e 's/^file_pickup = no/file_pickup = yes/' \
  -e 's/^permissions = no/permissions = yes/' \
  -e 's/^pre_script = no/pre_script = yes/' \
  -e 's/^during_script = no/during_script = yes/' \
  -e 's/^browsermonitor = no/browsermonitor = yes/' \
  /opt/CAPEv2/conf/auxiliary.conf
```

Then just make sure the file is still owned by cape:cape

```bash
sudo chown cape:cape /opt/CAPEv2/conf/auxiliary.conf
```

**cuckoo.conf**

```bash
sudo sed -i \
  -e 's/^machinery_screenshots = off/machinery_screenshots = on/' \
  -e 's/^memory_dump = off/memory_dump = on/' \
  -e 's/^reschedule = off/reschedule = on/' \
  -e 's/^freespace = 50000/freespace = 4096/' \
  -e 's/^freespace_processing = 15000/freespace_processing = 0/' \
  -e 's/^ip = 192\.168\.1\.1/ip = 0.0.0.0/' \
  -e 's/^store_csvs = off/store_csvs = on/' \
  -e 's/^upload_max_size = 100000000/upload_max_size = 1000000000/' \
  -e 's/^analysis_size_limit = 200000000/analysis_size_limit = 1000000000/' \
  -e 's/^timeout = .*/timeout = 150/' \
  -e 's/^default = 200/default = 300/' \
  -e 's/^critical = 60/critical = 300/' \
  -e 's/^enabled = off/enabled = on/' \
  -e 's/^enabled = no/enabled = yes/' \
  -e 's/^mongo = no/mongo = yes/' \
  -e 's/^unused_files_in_mongodb = no/unused_files_in_mongodb = yes/' \
  /opt/CAPEv2/conf/cuckoo.conf
```

And then fix ownership again so the cape user can still use it:

```bash
sudo chown cape:cape /opt/CAPEv2/conf/cuckoo.conf
```

**externalservices.conf**

This configuration file contains external integrations with `MISP` and `whoisxml` and are omitted for now.

**kvm.conf**

```bash
sudo sed -i \
  -e 's/^machines = cuckoo1/machines = windows10-1/' \
  -e 's/^\[cape1\]/[windows10-1]/' \
  -e 's/^label = cape1/label = windows10-1/' \
  -e 's/^platform = .*/platform = window/' \
  -e 's/^ip = 192\.168\.122\.105/ip = 192.168.122.250/' \
  -e 's/^arch = x86/arch = x64/' \
  -e 's/^# tags = winxp,acrobat_reader_6/tags = 22H2/' \
  -e 's/^# snapshot = Snapshot1/# snapshot = snapshot1/' \
  -e 's/^# resultserver_ip = 192\.168\.122\.101/resultserver_ip = 192.168.122.1/' \
  -e 's/^# reserved = no/reserved = no/' \
  /opt/CAPEv2/conf/kvm.conf
```

Keep ownership correct:

```bash
sudo chown cape:cape /opt/CAPEv2/conf/kvm.conf
```

**mitmdump.conf**

```bash
sudo sed -i 's/^host = 127\.0\.0\.1/host = 192.168.122.1/' /opt/CAPEv2/conf/mitmdump.conf
```

```bash
sudo chown cape:cape /opt/CAPEv2/conf/mitmdump.conf
```

**reporting.conf**

Optionally you can enable html and pdf reporting summary

**routing.conf**

```bash
sudo sed -i \
  -e 's/^enable_pcap = no/enable_pcap = yes/' \
  -e 's/^route = none/route = internet/' \
  -e 's/^internet = none/internet = virbr0/' \
  /opt/CAPEv2/conf/routing.conf
```

```bash
sudo chown cape:cape /opt/CAPEv2/conf/routing.conf
```

Restart CAPEv2 services

```bash
sudo systemctl restart cape.service
sudo systemctl restart cape-processor.service
sudo systemctl restart cape-rooter.service
sudo systemctl restart cape-web.service
sudo systemctl restart suricata.service
```

You can get error in the logs that snapshot cannot run due to permissions. For now I found fast fix of the issue, but for lab only that help me:

```bash
sudo chmod a+r /var/lib/libvirt/images/*
sudo aa-complain /etc/apparmor.d/usr.sbin.libvirtd 2>/dev/null || true
sudo aa-complain /etc/apparmor.d/libvirt/* 2>/dev/null || true
sudo systemctl reload apparmor
```

CAPEv2 will be available on management or lab IP address on port 8000 using http.
