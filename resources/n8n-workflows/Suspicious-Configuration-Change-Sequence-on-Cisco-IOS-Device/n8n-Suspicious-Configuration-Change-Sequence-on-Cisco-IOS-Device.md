# (n8n) Suspicious Configuration Change Sequence on Cisco IOS Device

When an Elastic rule is triggered based on the configured query, an alert will be created. Using the n8n solution, I want to show you some examples of what you can do. This is not a complete example, just a few useful cases such as enriching data with a VirusTotal verdict, generating a PDF report, and creating a case in DFIR IRIS.

The workflow backup will be attached to this repository, and you can download it. Secrets like usernames, passwords, or API keys will be cleaned up, so follow the guidelines to set them up correctly. Over time, the workflow may change, but the concepts described here will remain the same. You can access the JSON file [here](/resources/n8n-workflows/Suspicious-Configuration-Change-Sequence-on-Cisco-IOS-Device/topology/Suspicious-Configuration-Change-Sequence-on-Cisco-IOS-Device.json).

## Brief workflow overview

<div align="center">
    <img alt="Suspicious Configuration Change Sequence on Cisco IOS Device workflow" src="/resources/n8n-workflows/Suspicious-Configuration-Change-Sequence-on-Cisco-IOS-Device/images/topology.png" width="100%">
</div>

**(Execute workflow)**

Manual or scheduled trigger (for example, every 15 minutes)

**ELK [Get Security Alerts (FULL)]**

Add new node: Elasticsearch

Create new credentials

* Elasticsearch node username
* Elasticsearch node password
* Elasticsearch URL: https://172.16.10.5:9200
* Enable ignore SSL

Parameters 

* Resource: Document
* Operation: Get Many
* Index ID: `.alerts-security.alerts-default`
* Return All: enable
* Simplify: enable
* Add option -> Query (make sure to change timestamp based on your trigger):

```json
{
  "query": {
    "bool": {
      "must": [
        { "term": { "kibana.alert.workflow_status": "open" } },
        {
          "range": {
            "@timestamp": {
              "gte": "now-15m",
              "lte": "now"
            }
          }
        }
      ]
    }
  },
  "sort": [
    { "@timestamp": { "order": "desc" } }
  ]
}
```

This Elasticsearch node returns all data (simplified) from the declared index for a specific timeframe of opened alerts.

**ELK [Extract Interesting Data]**

Add new node: Set

Parameters

* Mode: Manual Mapping

Fields to set:

`kibana.agent.origical_time`

String
Expression:

```bash
{{ $json['kibana.alert.original_time'] }}
```

---

`kibana.alert.rule.name`

String

```bash
{{ $json['kibana.alert.rule.name'] }}
```

---

`kibana.alert.rule.severity`

String

```bash
{{ $json['kibana.alert.rule.severity'] }}
```

---

`source.ip`

String

```bash
{{$json["source.ip"] || ""}}
```

---

`source.user.name`

String

```bash
{{$json.source?.user?.name || ""}}
```

---

`event.code`

String

```bash
{{ $json['event.code'] }}
```

---

`message`

String

```bash
{{ $json['message'] }}
```

---

`kibana.alert.uuid`

String

```bash
{{ $json['kibana.alert.uuid'] }}
```

---

This node extracts only the relevant data mentioned above. An example is shown below:

```json
[
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:39.722Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "33f9b95f7b7c87655440a428a908c4205496e714"
      }
    },
    "source": {
      "ip": "",
      "user": {
        "name": ""
      }
    },
    "event": {
      "code": "PRIVCFG_ENCRYPT_SUCCESS"
    },
    "message": "Successfully encrypted private config file"
  },
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:35.628Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "a99df4000fa7a570da752631d2bf615fd03dc099"
      }
    },
    "source": {
      "ip": "",
      "user": {
        "name": ""
      }
    },
    "event": {
      "code": "CFGLOG_LOGGEDCMD"
    },
    "message": "User:vagrant  logged command:!config: USER TABLE MODIFIED"
  },
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:35.628Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "3f8bdf963ea8f7557f6aa1ca38917583c961b0e6"
      }
    },
    "source": {
      "ip": "",
      "user": {
        "name": ""
      }
    },
    "event": {
      "code": "SYNC_NEEDED"
    },
    "message": "Configuration change requiring running configuration sync detected - 'username *** privilege 15 secret ***'. The running configuration will be synchronized  to the NETCONF running data store."
  },
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:35.627Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "3245c65b48f5c86005355da874c7771ea6df1419"
      }
    },
    "source": {
      "ip": "",
      "user": {
        "name": ""
      }
    },
    "event": {
      "code": "CFGLOG_LOGGEDCMD"
    },
    "message": "User:vagrant  logged command:username adminprod privilege 15 secret *"
  },
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:00.388Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "5be9a35c360dcdbc595e539a4e0a35fa92e7f9ad"
      }
    },
    "source": {
      "ip": "100.66.0.6",
      "user": {
        "name": "vagrant"
      }
    },
    "event": {
      "code": "LOGIN_SUCCESS"
    },
    "message": "Login Success [user: vagrant] [Source: 100.66.0.6] [localport: 22] at 19:22:00 CEST Mon Sep 29 2025"
  }
]
```

**IF**

Add new node: If

Conditions:

* `{{ $json.source.ip }}` is not empty

This node outputs alerts that contain the `source.ip` address field (true) and those without the `source.ip` field (false).

Output (True branch)

```json
[
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:00.388Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "5be9a35c360dcdbc595e539a4e0a35fa92e7f9ad"
      }
    },
    "source": {
      "ip": "100.66.0.6",
      "user": {
        "name": "vagrant"
      }
    },
    "event": {
      "code": "LOGIN_SUCCESS"
    },
    "message": "Login Success [user: vagrant] [Source: 100.66.0.6] [localport: 22] at 19:22:00 CEST Mon Sep 29 2025"
  }
]
```

Output (False branch)

```json
[
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:39.722Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "33f9b95f7b7c87655440a428a908c4205496e714"
      }
    },
    "source": {
      "ip": "",
      "user": {
        "name": ""
      }
    },
    "event": {
      "code": "PRIVCFG_ENCRYPT_SUCCESS"
    },
    "message": "Successfully encrypted private config file"
  },
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:35.628Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "a99df4000fa7a570da752631d2bf615fd03dc099"
      }
    },
    "source": {
      "ip": "",
      "user": {
        "name": ""
      }
    },
    "event": {
      "code": "CFGLOG_LOGGEDCMD"
    },
    "message": "User:vagrant  logged command:!config: USER TABLE MODIFIED"
  },
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:35.628Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "3f8bdf963ea8f7557f6aa1ca38917583c961b0e6"
      }
    },
    "source": {
      "ip": "",
      "user": {
        "name": ""
      }
    },
    "event": {
      "code": "SYNC_NEEDED"
    },
    "message": "Configuration change requiring running configuration sync detected - 'username *** privilege 15 secret ***'. The running configuration will be synchronized  to the NETCONF running data store."
  },
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:35.627Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "3245c65b48f5c86005355da874c7771ea6df1419"
      }
    },
    "source": {
      "ip": "",
      "user": {
        "name": ""
      }
    },
    "event": {
      "code": "CFGLOG_LOGGEDCMD"
    },
    "message": "User:vagrant  logged command:username adminprod privilege 15 secret *"
  }
]
```

**VirusTotal** 

Create new credentials: provide API key only

Parameters

* Method: GET
* URL (expression): `https://www.virustotal.com/api/v3/ip_addresses/{{ $json.source.ip }}`

This node outputs a lot of data related to the analyzed IP address.

**VT-GET-STATS**

Fields to Set:

last_analysis_stats
Object
Expression:

```bash
{{ $('VirusTotal').first().json.data.attributes.last_analysis_stats }}
```

total_votes
Object
Expression:

```bash
{{ $('VirusTotal').first().json.data.attributes.total_votes }}
```

This node outputs just brief analysis statistics for `source.ip`. The IP address used in this lab will not have any IOCs. Example below:

```json
[
  {
    "last_analysis_stats": {
      "malicious": 0,
      "suspicious": 0,
      "undetected": 95,
      "harmless": 0,
      "timeout": 0
    },
    "total_votes": {
      "harmless": 0,
      "malicious": 0
    }
  }
]
```

**MERGE-VT-STATS-TO-IP**

Input 1: If
Input 2: VT-GET-STATS
Mode: Combine
Combine By: Position
Number of Inputs: 2

This node merges data from the If (true) branch, which has the IP address as `source.ip`, with VT-GET-STATS to produce enriched alerts. The output is shown below:

```json
[
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:00.388Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "5be9a35c360dcdbc595e539a4e0a35fa92e7f9ad"
      }
    },
    "source": {
      "ip": "100.66.0.6",
      "user": {
        "name": "vagrant"
      }
    },
    "event": {
      "code": "LOGIN_SUCCESS"
    },
    "message": "Login Success [user: vagrant] [Source: 100.66.0.6] [localport: 22] at 19:22:00 CEST Mon Sep 29 2025",
    "last_analysis_stats": {
      "malicious": 0,
      "suspicious": 0,
      "undetected": 95,
      "harmless": 0,
      "timeout": 0
    },
    "total_votes": {
      "harmless": 0,
      "malicious": 0
    }
  }
]
```

**Merge-ALL**

Input 1: If
Input 2: MERGE-VT-STATS-TO-IP
Mode: Append
Number of Inputs: 2

This node merges data from the If (false) branch node and MERGE-VT-STATS-TO-IP to have everything in one. Example below:

```json
[
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:39.722Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "33f9b95f7b7c87655440a428a908c4205496e714"
      }
    },
    "source": {
      "ip": "",
      "user": {
        "name": ""
      }
    },
    "event": {
      "code": "PRIVCFG_ENCRYPT_SUCCESS"
    },
    "message": "Successfully encrypted private config file"
  },
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:35.628Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "a99df4000fa7a570da752631d2bf615fd03dc099"
      }
    },
    "source": {
      "ip": "",
      "user": {
        "name": ""
      }
    },
    "event": {
      "code": "CFGLOG_LOGGEDCMD"
    },
    "message": "User:vagrant  logged command:!config: USER TABLE MODIFIED"
  },
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:35.628Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "3f8bdf963ea8f7557f6aa1ca38917583c961b0e6"
      }
    },
    "source": {
      "ip": "",
      "user": {
        "name": ""
      }
    },
    "event": {
      "code": "SYNC_NEEDED"
    },
    "message": "Configuration change requiring running configuration sync detected - 'username *** privilege 15 secret ***'. The running configuration will be synchronized  to the NETCONF running data store."
  },
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:35.627Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "3245c65b48f5c86005355da874c7771ea6df1419"
      }
    },
    "source": {
      "ip": "",
      "user": {
        "name": ""
      }
    },
    "event": {
      "code": "CFGLOG_LOGGEDCMD"
    },
    "message": "User:vagrant  logged command:username adminprod privilege 15 secret *"
  },
  {
    "kibana": {
      "agent": {
        "origical_time": "2025-09-29T17:22:00.388Z"
      },
      "alert": {
        "rule": {
          "name": "Suspicious Configuration Change Sequence on Cisco IOS Device",
          "severity": "high"
        },
        "uuid": "5be9a35c360dcdbc595e539a4e0a35fa92e7f9ad"
      }
    },
    "source": {
      "ip": "100.66.0.6",
      "user": {
        "name": "vagrant"
      }
    },
    "event": {
      "code": "LOGIN_SUCCESS"
    },
    "message": "Login Success [user: vagrant] [Source: 100.66.0.6] [localport: 22] at 19:22:00 CEST Mon Sep 29 2025",
    "last_analysis_stats": {
      "malicious": 0,
      "suspicious": 0,
      "undetected": 95,
      "harmless": 0,
      "timeout": 0
    },
    "total_votes": {
      "harmless": 0,
      "malicious": 0
    }
  }
]
```

The next two branches will be created for PDF generation and case creation in DFIR IRIS. The report will only be generated and viewable in the browser; you can add further logic by including an email node to send the report.

For case management, you can use any app for this purpose, it can be an HTTP POST node. I just want to demonstrate the scenario.

**Buid HTML**

Add node: Code (Javascript)

Parameters

* JavaScript:

```js
// Input: items[] from "Merge-ALL"
// Output: one item: { html: "<!doctype html>..." }

function esc(s) {
  return String(s ?? '')
    .replace(/&/g,'&amp;').replace(/</g,'&lt;')
    .replace(/>/g,'&gt;').replace(/"/g,'&quot;')
    .replace(/'/g,'&#39;');
}

const data = items.map(i => i.json);

// sort oldest � newest
data.sort(
  (a, b) => new Date(a?.kibana?.agent?.origical_time || 0) - new Date(b?.kibana?.agent?.origical_time || 0)
);

const generatedAt = new Date().toISOString();
const count = data.length;
const ruleName = data[0]?.kibana?.alert?.rule?.name || "";

let rows = '';

for (const e of data) {
  const t    = e?.kibana?.agent?.origical_time || '';
  const ip   = (e?.source?.ip || '').trim();
  const user = (e?.source?.user?.name || '').trim();
  const code = e?.event?.code || '';
  const msg  = e?.message || '';

  const stats = e?.last_analysis_stats;
  const votes = e?.total_votes;

  // Build meta rows, conditionally adding ip/user
  const metaLines = [
    `<div class="k"><span class="label">time</span></div><div class="v">${esc(t)}</div>`,
    `<div class="k"><span class="label">event.code</span></div><div class="v">${esc(code)}</div>`
  ];
  if (ip)   metaLines.push(`<div class="k"><span class="label">source.ip</span></div><div class="v">${esc(ip)}</div>`);
  if (user) metaLines.push(`<div class="k"><span class="label">user.name</span></div><div class="v">${esc(user)}</div>`);

  // VirusTotal rows in the same key/value spacing
  let vtBlock = '';
  if (stats || votes) {
    const vtLines = [];
    if (stats) {
      vtLines.push(
        `<div class="k head">VirusTotal � last_analysis_stats</div><div></div>`,
        `<div class="k"><span>malicious</span></div><div class="v">${stats.malicious ?? 0}</div>`,
        `<div class="k"><span>suspicious</span></div><div class="v">${stats.suspicious ?? 0}</div>`,
        `<div class="k"><span>undetected</span></div><div class="v">${stats.undetected ?? 0}</div>`,
        `<div class="k"><span>harmless</span></div><div class="v">${stats.harmless ?? 0}</div>`,
        `<div class="k"><span>timeout</span></div><div class="v">${stats.timeout ?? 0}</div>`
      );
    }
    if (votes) {
      vtLines.push(
        `<div class="k head">VirusTotal � total_votes</div><div></div>`,
        `<div class="k"><span>harmless</span></div><div class="v">${votes.harmless ?? 0}</div>`,
        `<div class="k"><span>malicious</span></div><div class="v">${votes.malicious ?? 0}</div>`
      );
    }
    vtBlock = `
      <div class="vt">
        <div class="kvgrid">
          ${vtLines.join('\n')}
        </div>
      </div>`;
  }

  rows += `
  <section class="card">
    <div class="meta">
      ${metaLines.join('\n')}
    </div>

    <div class="message"><pre>${esc(msg)}</pre></div>

    ${vtBlock}
  </section>`;
}

const html = `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>${esc(ruleName)}</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  /* A4-friendly */
  @page { size: A4; margin: 18mm; }
  html, body { height: 100%; }
  body {
    font: 12px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Inter,Arial,sans-serif;
    color:#111; margin:0;
  }

  .title { margin: 0 0 10px 0; }
  .title h1 { font-size: 20px; margin: 0 0 2px; font-weight: 800; }
  .small { font-size: 10px; color:#666; }

  .card {
    break-inside: avoid;
    border: 1px solid #ddd;
    border-radius: 8px;
    padding: 10px 12px;
    margin: 10px 0 14px;
    box-shadow: 0 1px 0 rgba(0,0,0,.03);
  }

  /* consistent 2-col label/value grid */
  .meta, .kvgrid {
    display: grid;
    grid-template-columns: 140px 1fr;
    column-gap: 12px;
    row-gap: 6px;
    align-items: start;
  }
  .label { font-weight: 700; color:#333; }
  .k.head { font-weight: 700; color:#333; padding-top: 6px; }
  .message { margin-top: 8px; }
  .message pre {
    background:#fbfbfb; border:1px solid #eee; border-radius:6px;
    padding:8px; white-space:pre-wrap; word-break:break-word; margin:0;
    font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, "Liberation Mono", monospace;
    font-size: 11px;
  }

  /* remove fixed footer to avoid overlap on page breaks */
</style>
</head>
<body>
  <div class="title">
    <h1>${esc(ruleName)}</h1>
    <div class="small">Items: ${count} " Generated: ${esc(generatedAt)}</div>
  </div>

  ${rows}
</body>
</html>`;

return [{ json: { html } }];
```

**Create HTML file**

Add node: Code (Javascript)

Parameters

* JavaScript:

```js
return items.map(it => {
  const html = it.json.html || '<!doctype html><html><body>No HTML</body></html>';

  return {
    json: {
      ...it.json,
    },
    binary: {
      report_html: {
        data: Buffer.from(html).toString('base64'),
        mimeType: 'text/html',
        fileExtension: 'html',
        fileName: 'index.html',
      }
    }
  };
});
```

**HTTP Request (Generate report)**

Add new node: HTTP Request

Parameters:

* Method: POST
* URL: `http://172.16.10.7:3000/forms/chromium/convert/html`
* Send Body: enabled
* Body Content Type: Form-Data
* Body Parameters: 
    * Parameter Type: n8n Binary File
    * Name: files
    * Input Data Field Name: report_html
* Add option Response:
    * Response Fornat: File
    * Put Output in Field: pdf

This node will generate a PDF file. You can check a sample [here](/resources/n8n-workflows/Suspicious-Configuration-Change-Sequence-on-Cisco-IOS-Device/reports/Suspicious-Configuration-Change-Sequence-on-Cisco-IOS-Device.pdf)

Another branch is for creating a case.

**Build-Summary**

Add new node: Core

Parameters:

* JavaScript:

```js
// Collect from the node named "Merge-ALL"
const src = $items("Merge-ALL");
if (!src.length) throw new Error("Merge-ALL produced no items");

let arr;
if (src.length === 1) {
  const j = src[0].json;
  if (Array.isArray(j)) arr = j;
  else if (typeof j === "string") arr = JSON.parse(j);
  else arr = [j];
} else {
  arr = src.map(i => i.json);
}

// Build simple text lines (ASCII dash instead of bullet)
const lines = arr.map(o => {
  const t = o?.kibana?.agent?.origical_time || "";
  const code = o?.event?.code || "";
  const user = o?.source?.user?.name || "";
  const ip = o?.source?.ip || "";
  const msg = o?.message || "";
  const who = [user && `user:${user}`, ip && `ip:${ip}`].filter(Boolean).join(" ");
  return `- ${t}  ${code}${who ? ` [${who}]` : ""} - ${msg}`;
});

// Title from rule name if present
const title = arr?.[0]?.kibana?.alert?.rule?.name || "Network device config change";
const summary = `Summary (${arr.length} events)  ${title}\n` + lines.join("\n");

// Output ONE item
return [{ json: { summary, raw: arr, title } }];
```

The output will contain a summary in text format and the raw data of all alerts in the chain.

**DFIR-IRIS-ADD-ALERT**

When using DFIR IRIS for case creation, you first need to create an alert and then escalate it to a case.

Add new node: DFIR-IRIS

Add new credentials. The default lab implementation uses a simple API key: `vagrant`.

Parameters:

* Method: POST
* URL: https://172.16.10.6/alerts/add
* Send Body: enable
* Body Content Type: JSON 
* Specific Body: JSON
* JSON:

```js
{{
{
  "alert_title": $json.title || "Suspicious Configuration Change Sequence on Cisco IOS Device",
  "alert_source": "Elastic",
  "alert_description": $json.summary,
  "alert_note": "Auto-import from n8n",
  "alert_status_id": 1,
  "alert_severity_id": 3,
  "alert_customer_id": 1,
  "alert_classification_id": 6,
  "alert_source_content": { "raw": $json.raw }
}
}}
```

* Add option: Ignore SSL

**DFIR-IRIS-ADD-CASE**

Parameters:

* Method: POST
* URL: `https://172.16.10.6/alerts/escalate/{{ $json.data.alert_id }}`
* Send Body: enable
* Body Content Type: JSON
* Specific Body: Using JSON
* JSON:

```js
{{
{
  "case_title": $json.data.alert_title,
  "case_tags": "cisco,ios,config-change,ssh",
  "import_as_event": true,
  "note": "Auto-escalated from n8n.",
  "iocs_import_list": [],
  "assets_import_list": []
}
}}
```

* Add option: Ignore SSL

In the DFIR IRIS Web UI, you will see the created Alert and Case.

<div align="center">
    <img alt="Suspicious Configuration Change Sequence on Cisco IOS Device DFIR IRIS alert" src="/resources/n8n-workflows/Suspicious-Configuration-Change-Sequence-on-Cisco-IOS-Device/images/dfir-iris-alert.png" width="100%">
</div>

<div align="center">
    <img alt="Suspicious Configuration Change Sequence on Cisco IOS Device DFIR IRIS case" src="/resources/n8n-workflows/Suspicious-Configuration-Change-Sequence-on-Cisco-IOS-Device/images/dfir-iris-case.png" width="100%">
</div>
