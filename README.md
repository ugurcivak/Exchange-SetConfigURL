# Exchange-SetConfigURL

> PowerShell automation script to quickly configure Internal and External Virtual Directory URLs and Autodiscover SCP records across Microsoft Exchange Server (2013, 2016, 2019, and Subscription Edition).

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%20%2F%20Exchange%20Management%20Shell-blue.svg)](https://learn.microsoft.com/powershell/exchange/)
[![Exchange Server](https://img.shields.io/badge/Exchange-2013%20%7C%202016%20%7C%202019%20%7C%20SE-blue)](https://learn.microsoft.com/exchange/exchange-server)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📌 Overview

Post-installation configuration of Microsoft Exchange Server requires setting up multiple Virtual Directories for internal and external access to avoid SSL certificate warnings and connectivity issues for Outlook, Mobile (ActiveSync), and Web (OWA/ECP) clients.

`SetExchangeURLs.ps1` automates this entire process:
- You only provide your primary FQDN (e.g. `mail.contoso.com`).
- The script automatically builds and assigns the standard endpoint paths across all relevant Exchange services.
- Protects remoting connectivity by **not touching** the PowerShell virtual directory.

---

## 🚀 Services Configured

| Service / Endpoint | Description | Path Assigned |
| :--- | :--- | :--- |
| **OWA** | Outlook on the web | `https://<FQDN>/owa` |
| **ECP** | Exchange Control Panel / EAC | `https://<FQDN>/ecp` |
| **ActiveSync** | Exchange Mobile ActiveSync | `https://<FQDN>/Microsoft-Server-ActiveSync` |
| **EWS** | Exchange Web Services | `https://<FQDN>/EWS/Exchange.asmx` |
| **OAB** | Offline Address Book | `https://<FQDN>/OAB` |
| **MAPI/HTTP** | Modern Outlook MAPI Endpoint | `https://<FQDN>/mapi` |
| **Autodiscover (SCP)** | Active Directory Service Connection Point | `https://<FQDN>/Autodiscover/Autodiscover.xml` |
| **Outlook Anywhere** | Legacy RPC/HTTP Fallback | Hostnames & Negotiate/NTLM Auth |

---

## ⚙️ Parameters

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :---: | :---: | :--- |
| `-Server` | `String[]` | **Yes** | — | Target Exchange server name(s). Accepts array or pipeline input. |
| `-InternalURL` | `String` | **Yes** | — | Internal FQDN (e.g. `mail.contoso.com`). |
| `-ExternalURL` | `String` | No | `""` | External FQDN (e.g. `mail.contoso.com`). If empty/omitted, External URLs are set to `$null`. |
| `-DefaultAuth` | `String` | No | `Negotiate` | Authentication method for Outlook Anywhere (`Negotiate`, `NTLM`, `Basic`). |
| `-AutodiscoverURL` | `String` | No | `$InternalURL` | Custom FQDN for Autodiscover SCP (e.g. `autodiscover.contoso.com`). |
| `-InternalSSL` | `Boolean` | No | `$true` | Internal clients require SSL for Outlook Anywhere. |
| `-ExternalSSL` | `Boolean` | No | `$true` | External clients require SSL for Outlook Anywhere. |
| `-WhatIf` | `Switch` | No | — | Shows what would happen without actually making any changes. |

---

## 📖 Usage Examples

### 1. Single Server Configuration (Standard Split-DNS)
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH01" -InternalURL "mail.contoso.com" -ExternalURL "mail.contoso.com"
```

### 2. Multi-Server / DAG Environment
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH01","EXCH02" -InternalURL "mail.contoso.com" -ExternalURL "mail.contoso.com"
```

### 3. Simulation Mode (`-WhatIf`)
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH01" -InternalURL "mail.contoso.com" -ExternalURL "mail.contoso.com" -WhatIf
```

### 4. Separate Autodiscover Domain
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH01" -InternalURL "mail.contoso.com" -ExternalURL "mail.contoso.com" -AutodiscoverURL "autodiscover.contoso.com"
```

### 5. Internal-Only / Split-DNS with No External Exposure
```powershell
.\SetExchangeURLs.ps1 -Server "EXCH01" -InternalURL "mail.contoso.com" -ExternalURL ""
```

---

## 🔒 Safety & Best Practices

- **Input Sanitization:** Automatically strips leading `http://` / `https://` protocols and trailing slashes `/` to prevent malformed URLs (e.g., `https://https://...`).
- **PowerShell VDir Preserved:** Does **not** modify `/powershell` virtual directory to avoid breaking WinRM and Exchange Management Shell remote sessions.
- **Modern Standards:** Default authentication method uses `Negotiate` (Kerberos-first with NTLM fallback) instead of plain NTLM.
- **Exchange Compatibility:** Compatible with Exchange 2013, 2016, 2019, and Subscription Edition using dynamic `Set-ClientAccessService` / `Set-ClientAccessServer` detection.

---

## 👤 Author

* **Uğur CIVAK**
* GitHub: [@ugurcivak](https://github.com/ugurcivak)
* Website: [sistemduragi.com](https://www.sistemduragi.com) / [maestropanel.com](https://www.maestropanel.com)

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
