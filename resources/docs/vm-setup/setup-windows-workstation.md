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

