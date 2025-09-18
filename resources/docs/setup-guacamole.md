# Setup Guacamole

Navigate to `https://localhost:8443` in your browser. Use the default credentials `guacadmin` / `guacadmin` to log in. You can create a new user or reset the password in the settings.

In the top-right corner, go to the `Settings` page, move to `Connections`, and create a new one.

## New Windows connection (RDP)

Enter the **name** of your new connection to the Windows VM. Change the protocol to **RDP** and go to the **PARAMETERS** section.

* In the **hostname** field, provide the management IP address of the Windows VM (in the `192.168.225.0/24` network) based on the [topology](/resources/images/vagrant-lab-virtual-topology.svg).
* For **port**, use `3389`.
* In the **Authentication** section, set the username and password to *vagrant*.
* In **security mode**, select *any*, check the box for *Ignore server certificate*, and also check *Trust host certificate on first use*.

Scroll to the bottom of the page and click **Save**.

In the top-right corner, click **Home**, and on the main page you will see your connections.
