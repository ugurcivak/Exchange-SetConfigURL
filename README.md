# Exchange-SetConfigURL

> PowerShell automation tool for Microsoft Exchange Server post-installation setup: Virtual Directories (Internal/External URLs), Autodiscover SCP management, Outbound Send Connectors, and Organization Message Size Limits.

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%2F%20Exchange%20Management%20Shell-blue.svg)](https://learn.microsoft.com/powershell/exchange/)
[![Exchange Server](https://img.shields.io/badge/Exchange-2013%20%7C%202016%20%7C%202019%20%7C%20SE-blue)](https://learn.microsoft.com/exchange/exchange-server)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📌 Overview

After completing a fresh installation or major migration of Microsoft Exchange Server, administrators face essential configuration tasks to ensure seamless mail flow and avoid SSL certificate mismatch warnings.

`SetExchangeURLs.ps1` consolidates and automates these post-installation requirements into a single, standardized command:
1. **Virtual Directory Configuration:** Automatically applies standard endpoint paths for OWA, ECP, ActiveSync, EWS, OAB, MAPI/HTTP, and Outlook Anywhere.
2. **Autodiscover SCP Management:** Updates the Active Directory Service Connection Point (`AutoDiscoverServiceInternalUri`) to match your trusted SSL certificate, or clears it (`$null`) for **Office 365 / EXO Relay** environments.
3. **Outbound Internet Send Connector (Optional):** Creates a standard DNS-routed Send Connector (`SMTP:*`) if one does not already exist.
4. **Global Message Size Limits (Optional):** Adjusts maximum send and receive message size limits across the entire organization (TransportConfig, Send Connectors, and Receive Connectors).
5. **Preserves PowerShell Remoting:** Intentionally skips the `/powershell` virtual directory to prevent breaking WinRM and Exchange Management Shell (EMS) remote sessions.

---

## 🚀 Services & Endpoints Configured

| Service / Endpoint | Description | Default Path Assigned |
| :--- | :--- | :--- |
| **OWA** | Outlook on the web | `https://<FQDN>/owa` |
| **ECP** | Exchange Control Panel / EAC | `https://<FQDN>/ecp` |
| **ActiveSync** | Exchange Mobile ActiveSync (EAS) | `https://<FQDN>/Microsoft-Server-ActiveSync` |
| **EWS** | Exchange Web Services | `https://<FQDN>/EWS/Exchange.asmx` |
| **OAB** | Offline Address Book | `https://<FQDN>/OAB` |
| **MAPI/HTTP** | Modern Outlook MAPI Protocol | `https://<FQDN>/mapi` |
| **Autodiscover (SCP)** | Active Directory Service Connection Point | `https://<FQDN>/Autodiscover/Autodiscover.xml` *(or `$null`)* |
| **Outlook Anywhere** | Legacy RPC/HTTP Fallback | Internal/External Hostnames with `Negotiate` / `NTLM` |

---

## ⚙️ Parameters

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `-Server` | `String[]` | **Yes** | — | Target Exchange server name(s). Accepts single string, array, or pipeline input. |
| `-InternalURL` | `String` | **Yes** | — | Primary Internal FQDN (e.g. `mail.contoso.com`). |
| `-ExternalURL` | `String` | No | `""` | Primary External FQDN (e.g. `mail.contoso.com`). If empty or omitted, External URLs are reset to `$null` (Split-DNS / Internal-only). |
| `-DefaultAuth` | `String` | No | `Negotiate` | Authentication method for Outlook Anywhere (`Negotiate`, `NTLM`, `Basic`). |
| `-AutodiscoverURL` | `String` | No | `$InternalURL` | Custom FQDN for Autodiscover SCP (e.g. `autodiscover.contoso.com`). |
| `-DisableSCP` | `Switch` | No | `$false` | Sets `AutoDiscoverServiceInternalUri` to `$null`. Ideal for on-premise Exchange servers used strictly as internal SMTP Relays while user mailboxes reside in **Office 365 / Exchange Online (EXO)**. |
| `-CreateSendConnector`| `Switch` | No | `$false` | Automatically creates an Outbound Internet Send Connector (`SMTP:*`, DNS routing) if no wildcard connector exists. |
| `-MaxMessageSize` | `String` | No | — | Sets global message size limits across TransportConfig, all Send Connectors, and all Receive Connectors (e.g. `"50MB"`, `"100MB"`). |
| `-InternalSSL` | `Boolean` | No | `$true` | Specifies whether internal clients require SSL for Outlook Anywhere. |
| `-ExternalSSL` | `Boolean` | No | `$true` | Specifies whether external clients require SSL for Outlook Anywhere. |
| `-WhatIf` | `Switch` | No | — | Simulates the actions that would be performed without applying changes. |

---

## 📖 Real-World Usage Scenarios

### Scenario 1: Standard On-Premises Exchange Setup (Full Post-Config)
Configures all Virtual Directories, sets Autodiscover SCP to `mail.contoso.com`, creates an Outbound Internet Send Connector, and sets a 50MB global message limit:
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH01" `
    -InternalURL "mail.contoso.com" `
    -ExternalURL "mail.contoso.com" `
    -CreateSendConnector `
    -MaxMessageSize "50MB"
```

### Scenario 2: Multi-Server / Database Availability Group (DAG)
Applies the configuration across multiple Exchange servers simultaneously:
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH01","EXCH02" `
    -InternalURL "mail.contoso.com" `
    -ExternalURL "mail.contoso.com"
```

### Scenario 3: Office 365 (EXO) Mailboxes with On-Premises SMTP Relay Server
When user mailboxes are in Exchange Online (Office 365) and on-premises Exchange is only used for application/device SMTP relay, internal domain-joined Outlook clients must **not** query on-premises AD for Autodiscover:
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH-RELAY" `
    -InternalURL "mail.contoso.com" `
    -ExternalURL "" `
    -DisableSCP
```
> **How it works:** Setting `-DisableSCP` clears the Active Directory SCP (`$null`). Internal Outlook clients will bypass the local relay server and resolve Autodiscover directly via DNS (CNAME/SRV) to `autodiscover.outlook.com`.

### Scenario 4: Custom Dedicated Autodiscover Domain
When using a dedicated SAN/FQDN for Autodiscover:
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH01" `
    -InternalURL "mail.contoso.com" `
    -ExternalURL "mail.contoso.com" `
    -AutodiscoverURL "autodiscover.contoso.com"
```

### Scenario 5: Simulation & Audit Mode (`-WhatIf`)
Preview the exact changes before executing:
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH01" `
    -InternalURL "mail.contoso.com" `
    -ExternalURL "mail.contoso.com" `
    -WhatIf
```

---

## 🔒 Safety & Best Practices

- **Input Sanitization:** Automatically cleans inputs by stripping accidental `http://` / `https://` prefixes and trailing `/` slashes.
- **PowerShell VDir Preserved:** Never modifies `/powershell` virtual directory to avoid breaking Kerberos authentication and EMS remote sessions.
- **Modern Security Standards:** Uses `Negotiate` (Kerberos-first with NTLM fallback) as the default authentication method for Outlook Anywhere.
- **Exchange Version Agnostic:** Dynamically uses modern `Set-ClientAccessService` (Exchange 2016 / 2019 / SE) with fallback to legacy `Set-ClientAccessServer` (Exchange 2013).

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
