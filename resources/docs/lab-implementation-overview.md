# Lab Implementation Overview

First, check the requirements before you go to setup the lab. After you setup the Debian-based host, you will need to build vagrant boxes. For now, the lab is mainly based on FortiGate and Cisco 8kv images, and based on them, some scenarios are created. Later, free or open-source solutions will be added. For now, the manual setup is described, and after some time I will add a new section with auto lab setup. This will be based on the attached ansible provisioning scripts for the vagrant boxes.

The description in this lab setup is hardcoded, as shown in the topology - like UDP tunnels, management IP addresses, and in-lab addressing. Take this into consideration if you want to change something.

