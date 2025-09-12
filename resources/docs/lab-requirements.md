Nested virtualization does not work well. I do not recommend using Windows with VirtualBox (or other software) to run virtualized Linux and build the lab on it. Instead, use Linux with **dual boot or run the lab on separate hardware**.

Before starting the lab, make sure you have:

- **Virtualization enabled in the BIOS**
- **Debian 12** installed with DE (I will use XFCE in this project)
- **Static IP address** on your Linux host;
- **SSH and/or RDP access** to the Linux host;
- **User with sudo** privileges on the Linux host
- **Code editor** installed on the Linux host, for example VS Code

System requirements (minimum):

- **12-16 vCPUs**
- **48 GB RAM**
- **200 GB disk space** (depending on how long you plan to keep your lab running)

Even if I said not to use nested virtualization (especially on old hardware) - I will run a Debian 12 VM under Fedora Linux on my laptop to test the instructions for this lab one more time.

<div align="center">
    <img alt="Main host neowofetch" src="/resources/images/main-host-neowofetch.png" width="100%">
</div>
