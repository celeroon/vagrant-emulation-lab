# Suspicious Configuration Change Sequence on Cisco IOS Device

For this scenario the Cisco branch router must be deployed. As initial access I will use SSH to the router directly to initiate further movement on the network.

The purpose of this lab is not to find or develop a vulnerability - those can appear in any version any day. This is about what we will see if somebody enters the network.

Opening an RDP session in Guacamole to the Kali Linux VM will give initial access to the branch router via SSH. In this example, even by sending a simple syslog you can get logs that someone logged in via SSH. You can play with this data and create rules, for example: when an admin account is allowed to log in and you have whitelisted IP addresses, exclude them in the rule.

<div align="center">
    <img alt="Branch router SSH" src="/resources/docs/scenarios/attack-detect/initial-access/network-service/common-service-attack/images/branch-router-ssh.png" width="100%">
</div>

The brute-force followed by a successful login on the SIEM will look like this:

<div align="center">
    <img alt="Branch router SSH" src="/resources/docs/scenarios/attack-detect/initial-access/network-service/common-service-attack/images/branch-router-ssh-2.png" width="100%">
</div>

Another detection idea is brute force followed by successful login. But in this scenario I want to implement a rule for a successful login to the router followed by config changes. This may be executed in many cases because the threat actor will come back later — for example to create a new account with admin privileges.

<div align="center">
    <img alt="Cisco router config change" src="/resources/docs/scenarios/attack-detect/initial-access/network-service/common-service-attack/images/cisco-router-config-change-1.png" width="100%">
</div>

This was the Discovery tab where you can check raw logs. Based on this data we will create a new rule using EQL. Navigate to Security -> Timelines and create a new timeline. Remember to select the Data View — it must be `logs-*`.

```bash
sequence by log.source.address with maxspan=10m
  [ any where data_stream.dataset == "cisco_ios.log" and event.code == "LOGIN_SUCCESS" ]
  [ any where data_stream.dataset == "cisco_ios.log" and event.code == "SYNC_NEEDED" ]
  [ any where data_stream.dataset == "cisco_ios.log" and event.code == "PRIVCFG_ENCRYPT_SUCCESS" ]
```

<div align="center">
    <img alt="Cisco router timelines" src="/resources/docs/scenarios/attack-detect/initial-access/network-service/common-service-attack/images/cisco-router-logs-timelines-1.png" width="100%">
</div>

You can also use an ESQL query by switching to the Discover tab:

```bash
FROM logs-* METADATA _id, _version, _index
| WHERE data_stream.dataset == "cisco_ios.log"
  AND event.code IN ("LOGIN_SUCCESS","SYNC_NEEDED","PRIVCFG_ENCRYPT_SUCCESS")
| EVAL dev = log.source.address
| KEEP @timestamp, source.ip, event.code, message, _id, _version, _index
| SORT @timestamp ASC
```

<div align="center">
    <img alt="Cisco router ESQL" src="/resources/docs/scenarios/attack-detect/initial-access/network-service/common-service-attack/images/cisco-router-logs-esql-1.png" width="100%">
</div>

To create an Elastic rule, navigate to Security -> Rules -> Create new. You can use ESQL or EQL as the detection language, and fill other fields such as name, description, MITRE mapping, etc. You can [get the rule here](/resources/docs/scenarios/attack-detect/initial-access/network-service/common-service-attack/rules/Suspicious-Configuration-Change-Sequence-on-Cisco-IOS-Device.ndjson). This rule is saved as an NDJSON document. If you want to import it into Elasticsearch you need to convert it to a one-line format. All rules are disabled by default.

Navigate to the Discovery and switch to the **Security alert data view**. You will see alerts triggered by the configured sequences, such as login, configuration changes, and saving.

<div align="center">
    <img alt="Cisco router alert" src="/resources/docs/scenarios/attack-detect/initial-access/network-service/common-service-attack/images/cisco-router-alert-1.png" width="100%">
</div>
