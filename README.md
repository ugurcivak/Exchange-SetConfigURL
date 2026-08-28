# Exchange-SetConfigURL

> Fast, automated PowerShell configuration for Microsoft Exchange Server (2013, 2016, 2019, SE) Virtual Directory URLs, Autodiscover SCP, Outbound Send Connectors, and Message Limits.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%2F%20EMS-blue.svg)](https://learn.microsoft.com/powershell/exchange/)
[![Exchange Server](https://img.shields.io/badge/Exchange-2013%20%7C%202016%20%7C%202019%20%7C%20SE-blue)](https://learn.microsoft.com/exchange/exchange-server)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## ✨ Features

- ⚡ **All Virtual Directories:** Automatically configures OWA, ECP, ActiveSync, EWS, OAB, MAPI/HTTP, and Outlook Anywhere.
- 🔍 **Smart Autodiscover SCP:** Sets AD SCP to your trusted domain or clears it (`$null`) for **Office 365 / EXO Relay** setups.
- ✉️ **Send Connector:** Creates an outbound Internet Send Connector (`SMTP:*`, DNS routing) if missing (`-CreateSendConnector`).
- 📦 **Message Limits:** Sets global send/receive limits across Transport and all connectors in one shot (`-MaxMessageSize "50MB"`).
- 🛡️ **Safe by Default:** Strips URL typos, supports `-WhatIf` dry-runs, and protects `/powershell` VDir to preserve EMS remoting.

---

## 🖥️ Demo / Terminal Preview

```text
PS C:\> .\SetExchangeURLs.ps1 -Server "EXCH01" `
    -InternalURL "mail.contoso.com" `
    -ExternalURL "mail.contoso.com" `
    -CreateSendConnector `
    -MaxMessageSize "50MB"

[*] Checking Exchange Management Session...
[+] Configuring Organization Message Size Limits (50MB)...
    [✓] Organization Transport, Send, and Receive connector limits set to 50MB.
[+] Checking Outbound Internet Send Connector...
    [✓] Successfully created 'Outbound to Internet' Send Connector.

========================================================
 Configuring Exchange Server: EXCH01
 Internal URL       : https://mail.contoso.com
 External URL       : https://mail.contoso.com
 Authentication     : Negotiate
 Autodiscover SCP   : https://mail.contoso.com/Autodiscover/Autodiscover.xml
========================================================

[+] Configuring Outlook Anywhere...
[+] Configuring Outlook on the Web (OWA)...
[+] Configuring Exchange Control Panel (ECP)...
[+] Configuring Exchange ActiveSync (EAS)...
[+] Configuring Exchange Web Services (EWS)...
[+] Configuring Offline Address Book (OAB)...
[+] Configuring MAPI over HTTP...
[+] Configuring Autodiscover SCP Internal URI...

[✓] Successfully configured 'EXCH01'.

========================================================
 [✓] Execution Complete!
========================================================
```

---

## 🚀 Quick Examples

### 1. Full Setup (URLs + Send Connector + 50MB Limits)
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH01" `
    -InternalURL "mail.contoso.com" `
    -ExternalURL "mail.contoso.com" `
    -CreateSendConnector `
    -MaxMessageSize "50MB"
```

### 2. Basic URL Configuration Only
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH01" -InternalURL "mail.contoso.com" -ExternalURL "mail.contoso.com"
```

### 3. Multi-Server / DAG Setup
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH01","EXCH02" -InternalURL "mail.contoso.com" -ExternalURL "mail.contoso.com"
```

### 4. Office 365 / EXO Relay Only (Disable SCP)
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH-RELAY" -InternalURL "mail.contoso.com" -ExternalURL "" -DisableSCP
```

### 5. Dry-Run / Simulation Mode
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH01" -InternalURL "mail.contoso.com" -ExternalURL "mail.contoso.com" -WhatIf
```

---

## ⚙️ Parameters

| Parameter | Type | Default | Description |
| :--- | :---: | :---: | :--- |
| `-Server` | `String[]` | *Required* | Target Exchange server name(s). |
| `-InternalURL` | `String` | *Required* | Internal FQDN (e.g. `mail.contoso.com`). |
| `-ExternalURL` | `String` | `""` | External FQDN. If omitted, external URLs are set to `$null`. |
| `-CreateSendConnector` | `Switch` | `$false` | Creates outbound Internet Send Connector (`SMTP:*`). |
| `-MaxMessageSize` | `String` | *None* | Sets global message limit (e.g. `"50MB"`). |
| `-DisableSCP` | `Switch` | `$false` | Clears AD SCP (`$null`) for Office 365 / EXO relay servers. |
| `-AutodiscoverURL` | `String` | `$InternalURL` | Custom FQDN for Autodiscover SCP. |
| `-DefaultAuth` | `String` | `Negotiate` | Outlook Anywhere auth (`Negotiate`, `NTLM`, `Basic`). |
| `-WhatIf` | `Switch` | — | Simulates changes without applying. |

---

## 📄 License

MIT License. See [LICENSE](LICENSE) for details.
