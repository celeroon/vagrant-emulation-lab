# Setup Windows Workstation

Based on your choise to use Windows 10 or Windows 11 in the initial host setup stage - you need to modify the `node.vm.box` in the file location `vms/windows/users/config.rb`. Use `vagrant box list` command to identify your Windows box name. By default I will use Windows 11 box (`windows-11-24h2-amd64`).

Run VM (there are two VM predifind: win-user-1 and win-user-2)

```bash
vagrant up win-user-1
```

While you wait for Windows VM initialization you can configure [Guacamole using instrcutions](/resources/docs/setup-guacamole.md)

Alternativly you can you xfree rdp from localhost to the Windows VM, firsly you need to install service `sudo apt install freerdp2-x11` and use command below to connect to the VM

```bash
xfreerdp /u:vagrant /p:vagrant /v:192.168.225.21 /monitors:0 /multimon /port:3389
```

After you get access to the VM change network configuration to remove gateway on the management interaface. Select appropriate network card and edit settings.

<div align="center">
    <img alt="Windows network configuration" src="/resources/images/windows/workstation-network-properties.png" width="100%">
</div>

Refresh guacamole page because you will lost connection after changing network configuration. From main host working directory transfer `elasticsearch-ca.pem` to C:\ drive (if you have multiple Windows VM remember to change IP address)

```bash
scp -i ~/.vagrant.d/insecure_private_key ./ansible/artifacts/elasticsearch-ca.pem vagrant@192.168.225.21:/c:/elasticsearch-ca.pem
```

Add certificate to trust store

```powershell
certutil -addstore -f "Root" "C:\elasticsearch-ca.pem"
```

On the Windows VM we will use Chocolatey to isntall required software. First we ween to install tool. I recommend to use Google Chrome browser to easly coppy and paste commands to the VM. I recommend to open powershell as Administrator to run commands below. 

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

Install software via Chocolatey

```powershell
choco install git -y
choco install sysmon --version=15.14.0 --ignore-checksums -y
choco install filezilla -y
choco install googlechrome --version=134.0.6998.166 --ignore-checksums -y
choco install firefox -y
choco install visualstudio2019buildtools -y
choco install vcredist140 -y
choco install visualcpp-build-tools -y
choco install 7zip -y
```

Add Python to PATH (machine-wide)

```powershell
$currentPath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$newPath = $currentPath + ";C:\Python312;C:\Python312\Scripts"
[Environment]::SetEnvironmentVariable("Path", $newPath, "Machine")
```

Next step is to configure logging on a Windows VM. Create the Registry Key for Script Block Logging

```powershell
New-Item -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Force
```

Enable Script Block Logging

```powershell
Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Value 1 -Force
```

Next step is to change audit policy. You can copy and paste full script or create a powershell script file and transfer it via scp. Audit settings are based on [this baseline](https://github.com/celeroon/win-audit-policy-settings)

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

## ================== ##
# ==================== #
# Install velociraptor #
# ==================== #
## ================== ##

Download Sysmon config

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/olafhartong/sysmon-modular/master/sysmonconfig.xml" -OutFile "C:\sysmonconfig.xml"
```

Lets clear logs before Sysmon installation


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

To install Sysmon run command below

```powershell
C:\ProgramData\chocolatey\lib\sysmon\tools\sysmon64.exe -i C:\sysmonconfig.xml -accepteula
```

To install Elastic Agent navigate to the `https://172.16.10.5:5601` and go to the Fleet section. You will see `Add agent` blue button. After you click it - select `Windows-Policy` and on the bottom you will see script for `Windows x86_64`. Copy this code and paste to the powershell (with Admin rights) and append `--force` to this script or just access `Y` during installation. You will see your Windows VM in the Fleet server section.

<div align="center">
    <img alt="Windows Elastic Agent" src="/resources/images/windows/elastic-agent.png" width="100%">
</div>

It is recommended to update installed agent policies nativating to `Fleet -> Agent policies -> Windows Policy`. In the `System` integration you can disable collecting Windows metrics if you want to save more space on ELK VM.

Nativate to the `Fleet-Server-Policy` and on the right corner click `Add Integration`. Search for `NetFlow Records` and change `localhost` to the `0.0.0.0` and also UDP port from `2055` to `9012`. 

Now you can analyze dashboards for search `FortiGate` or `NetFlow` and check them.

<div align="center">
    <img alt="Elasticsearch Kibana NetFlow" src="/resources/images/windows/netflow-records.png" width="100%">
</div>
