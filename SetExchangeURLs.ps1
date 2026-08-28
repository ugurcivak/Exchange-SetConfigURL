<#
.SYNOPSIS
    Exchange Server Virtual Directory, Autodiscover, and Post-Installation Config Tool.

.DESCRIPTION
    Automates post-installation configuration for Microsoft Exchange Server (2013, 2016, 
    2019, and Subscription Edition).
    
    Capabilities:
    - Configures Internal and External URLs for Client Access Services (OWA, ECP, 
      ActiveSync, EWS, OAB, MAPI/HTTP, and Outlook Anywhere).
    - Sets or clears Active Directory Autodiscover SCP records (supports Office 365 / EXO Relay scenarios).
    - Optionally creates an Outbound Internet Send Connector.
    - Optionally configures global organization message size limits (Transport, Send, and Receive connectors).
    - Excludes the PowerShell Virtual Directory to preserve WinRM/EMS remoting connectivity.
    - Displays helpful post-installation recommendations and health tips upon completion.

.PARAMETER Server
    Specifies the target Exchange server name(s). Accepts an array of strings or pipeline input.

.PARAMETER InternalURL
    Specifies the internal FQDN (e.g. mail.domain.com).

.PARAMETER ExternalURL
    Specifies the external FQDN (e.g. mail.domain.com). 
    If left empty or set to "", External URLs will be reset to $null (Internal-only / Split-DNS).

.PARAMETER DefaultAuth
    Specifies the default authentication method for Outlook Anywhere.
    Supported values: 'Negotiate', 'NTLM', 'Basic'. Default is 'Negotiate'.

.PARAMETER AutodiscoverURL
    Optional. Specifies a custom Autodiscover FQDN (e.g. autodiscover.domain.com). 
    If not specified, defaults to InternalURL.

.PARAMETER DisableSCP
    Optional switch. Clears the Active Directory Service Connection Point (sets AutoDiscoverServiceInternalUri to $null).
    Recommended when Exchange is used solely as an internal SMTP Relay while mailboxes reside in Office 365 / EXO.

.PARAMETER CreateSendConnector
    Optional switch. Automatically creates an Outbound Internet Send Connector ("Outbound to Internet") 
    using DNS routing if no wildcard (SMTP:*) Send Connector currently exists.

.PARAMETER MaxMessageSize
    Optional. Sets global message size limits across TransportConfig, all Send Connectors, 
    and all Receive Connectors (e.g. "50MB", "100MB").

.PARAMETER InternalSSL
    Specifies whether internal clients require SSL for Outlook Anywhere. Default is $true.

.PARAMETER ExternalSSL
    Specifies whether external clients require SSL for Outlook Anywhere. Default is $true.

.EXAMPLE
    .\SetExchangeURLs.ps1 -Server "EXCH01" -InternalURL "mail.contoso.com" -ExternalURL "mail.contoso.com"

.EXAMPLE
    .\SetExchangeURLs.ps1 -Server "EXCH01","EXCH02" -InternalURL "mail.contoso.com" -ExternalURL "mail.contoso.com" -CreateSendConnector -MaxMessageSize "50MB"

.EXAMPLE
    .\SetExchangeURLs.ps1 -Server "EXCH-RELAY" -InternalURL "mail.contoso.com" -ExternalURL "" -DisableSCP

.NOTES
    Author : Ugur CIVAK
    GitHub : https://github.com/ugurcivak/Exchange-SetConfigURL

.LINK
    https://github.com/ugurcivak/Exchange-SetConfigURL
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
    [string[]]$Server,

    [Parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$InternalURL,

    [Parameter(Mandatory=$false)]
    [AllowEmptyString()]
    [string]$ExternalURL = "",

    [Parameter(Mandatory=$false)]
    [ValidateSet("Negotiate", "NTLM", "Basic")]
    [string]$DefaultAuth = "Negotiate",

    [Parameter(Mandatory=$false)]
    [string]$AutodiscoverURL,

    [Parameter(Mandatory=$false)]
    [switch]$DisableSCP,

    [Parameter(Mandatory=$false)]
    [switch]$CreateSendConnector,

    [Parameter(Mandatory=$false)]
    [string]$MaxMessageSize,

    [Parameter(Mandatory=$false)]
    [bool]$InternalSSL = $true,

    [Parameter(Mandatory=$false)]
    [bool]$ExternalSSL = $true
)

Begin {
    # 1. Input Sanitization (strip http(s):// prefix and trailing slashes)
    $InternalURL = $InternalURL -replace "^https?://", "" -replace "/+$", ""
    if ($ExternalURL) {
        $ExternalURL = $ExternalURL -replace "^https?://", "" -replace "/+$", ""
    }
    if ($AutodiscoverURL) {
        $AutodiscoverURL = $AutodiscoverURL -replace "^https?://", "" -replace "/+$", ""
    }

    # 2. Exchange Session Verification
    Write-Host "[*] Checking Exchange Management Session..." -ForegroundColor Cyan
    if (Get-Command Get-ExchangeServer -ErrorAction SilentlyContinue) {
        Write-Verbose "Exchange cmdlets are already loaded in current session."
    } elseif (Test-Path "$env:ExchangeInstallPath\bin\RemoteExchange.ps1") {
        Write-Verbose "Loading Exchange Management session..."
        . "$env:ExchangeInstallPath\bin\RemoteExchange.ps1"
        Connect-ExchangeServer -auto -AllowClobber | Out-Null
    } else {
        Write-Error "Exchange Server Management Tools were not found on this machine."
        return
    }

    # 3. Organization-Wide Message Size Configuration (if requested)
    if ($MaxMessageSize) {
        if ($PSCmdlet.ShouldProcess("Organization", "Set TransportConfig MaxSendSize & MaxReceiveSize to $MaxMessageSize")) {
            Write-Host "[+] Configuring Organization Message Size Limits ($MaxMessageSize)..." -ForegroundColor Yellow
            try {
                Set-TransportConfig -MaxSendSize $MaxMessageSize -MaxReceiveSize $MaxMessageSize -ErrorAction Stop
                Get-SendConnector -ErrorAction SilentlyContinue | Set-SendConnector -MaxMessageSize $MaxMessageSize -ErrorAction SilentlyContinue
                Get-ReceiveConnector -ErrorAction SilentlyContinue | Set-ReceiveConnector -MaxMessageSize $MaxMessageSize -ErrorAction SilentlyContinue
                Write-Host "    [✓] Organization Transport, Send, and Receive connector limits set to $MaxMessageSize." -ForegroundColor Green
            } catch {
                Write-Warning "[-] Failed to set message size limits: $($_.Exception.Message)"
            }
        }
    }

    # 4. Outbound Internet Send Connector Configuration (if requested)
    if ($CreateSendConnector) {
        if ($PSCmdlet.ShouldProcess("Organization", "Check/Create Outbound Internet Send Connector")) {
            Write-Host "[+] Checking Outbound Internet Send Connector..." -ForegroundColor Yellow
            $existingSendConnector = Get-SendConnector -ErrorAction SilentlyContinue | Where-Object { 
                $_.AddressSpaces | Where-Object { $_.Address -eq "*" }
            }

            if ($existingSendConnector) {
                Write-Host "    [i] Outbound Send Connector already exists: '$($existingSendConnector.Name)'" -ForegroundColor Gray
            } else {
                try {
                    New-SendConnector -Name "Outbound to Internet" -Usage Internet -AddressSpaces "SMTP:*;1" -DNSRoutingEnabled $true -SourceTransportServers $Server -ErrorAction Stop
                    Write-Host "    [✓] Successfully created 'Outbound to Internet' Send Connector." -ForegroundColor Green
                } catch {
                    Write-Warning "[-] Failed to create Send Connector: $($_.Exception.Message)"
                }
            }
        }
    }
}

Process {
    foreach ($srv in $Server) {
        $exchServer = Get-ExchangeServer $srv -ErrorAction SilentlyContinue
        if (-not $exchServer) {
            Write-Warning "[-] Exchange server '$srv' was not found in Active Directory!"
            continue
        }

        # Role verification (Exchange 2013 CAS or 2016/2019/SE Mailbox role)
        if (-not ($exchServer.IsClientAccessServer -or $exchServer.IsMailboxServer)) {
            Write-Warning "[-] '$srv' does not hold Client Access or Mailbox server role."
            continue
        }

        Write-Host "`n========================================================" -ForegroundColor Green
        Write-Host " Configuring Exchange Server: $srv" -ForegroundColor Green
        Write-Host " Internal URL       : https://$InternalURL" -ForegroundColor Gray
        Write-Host " External URL       : $(if ($ExternalURL) { "https://$ExternalURL" } else { "[DISABLED / NULL]" })" -ForegroundColor Gray
        Write-Host " Authentication     : $DefaultAuth" -ForegroundColor Gray
        if ($DisableSCP) {
            Write-Host " Autodiscover SCP   : [DISABLED / NULL] (EXO / Relay Scenario)" -ForegroundColor Gray
        } else {
            Write-Host " Autodiscover SCP   : https://$(if ($AutodiscoverURL) { $AutodiscoverURL } else { $InternalURL })/Autodiscover/Autodiscover.xml" -ForegroundColor Gray
        }
        Write-Host "========================================================`n" -ForegroundColor Green

        if ($PSCmdlet.ShouldProcess($srv, "Configure Virtual Directory and Autodiscover URLs")) {
            
            # Helper function to construct external virtual directory URL
            function Get-VDirExtUrl([string]$path) {
                if ($ExternalURL) { return "https://$ExternalURL/$path" } else { return $null }
            }

            # 1. Outlook Anywhere (RPC over HTTP)
            Write-Host "[+] Configuring Outlook Anywhere..." -ForegroundColor Yellow
            $oaParams = @{
                InternalHostname            = $InternalURL
                InternalClientsRequireSsl   = $InternalSSL
                ExternalClientsRequireSsl   = $ExternalSSL
                DefaultAuthenticationMethod = $DefaultAuth
                ErrorAction                 = "SilentlyContinue"
            }
            if ($ExternalURL) { $oaParams["ExternalHostname"] = $ExternalURL }
            Get-OutlookAnywhere -Server $srv -ErrorAction SilentlyContinue | Set-OutlookAnywhere @oaParams

            # 2. OWA (Outlook on the web)
            Write-Host "[+] Configuring Outlook on the Web (OWA)..." -ForegroundColor Yellow
            Get-OwaVirtualDirectory -Server $srv | Set-OwaVirtualDirectory -InternalUrl "https://$InternalURL/owa" -ExternalUrl (Get-VDirExtUrl "owa")

            # 3. ECP (Exchange Control Panel / Admin Center)
            Write-Host "[+] Configuring Exchange Control Panel (ECP)..." -ForegroundColor Yellow
            Get-EcpVirtualDirectory -Server $srv | Set-EcpVirtualDirectory -InternalUrl "https://$InternalURL/ecp" -ExternalUrl (Get-VDirExtUrl "ecp")

            # 4. Exchange ActiveSync (EAS)
            Write-Host "[+] Configuring Exchange ActiveSync (EAS)..." -ForegroundColor Yellow
            Get-ActiveSyncVirtualDirectory -Server $srv | Set-ActiveSyncVirtualDirectory -InternalUrl "https://$InternalURL/Microsoft-Server-ActiveSync" -ExternalUrl (Get-VDirExtUrl "Microsoft-Server-ActiveSync")

            # 5. EWS (Exchange Web Services)
            Write-Host "[+] Configuring Exchange Web Services (EWS)..." -ForegroundColor Yellow
            Get-WebServicesVirtualDirectory -Server $srv | Set-WebServicesVirtualDirectory -InternalUrl "https://$InternalURL/EWS/Exchange.asmx" -ExternalUrl (Get-VDirExtUrl "EWS/Exchange.asmx")

            # 6. OAB (Offline Address Book)
            Write-Host "[+] Configuring Offline Address Book (OAB)..." -ForegroundColor Yellow
            Get-OabVirtualDirectory -Server $srv | Set-OabVirtualDirectory -InternalUrl "https://$InternalURL/OAB" -ExternalUrl (Get-VDirExtUrl "OAB")

            # 7. MAPI over HTTP
            Write-Host "[+] Configuring MAPI over HTTP..." -ForegroundColor Yellow
            Get-MapiVirtualDirectory -Server $srv -ErrorAction SilentlyContinue | Set-MapiVirtualDirectory -InternalUrl "https://$InternalURL/mapi" -ExternalUrl (Get-VDirExtUrl "mapi")

            # 8. Autodiscover Service Internal URI (Active Directory SCP)
            if ($DisableSCP) {
                Write-Host "[+] Disabling Autodiscover SCP (setting to `$null for EXO/Relay scenario)..." -ForegroundColor Yellow
                if (Get-Command Set-ClientAccessService -ErrorAction SilentlyContinue) {
                    Get-ClientAccessService $srv | Set-ClientAccessService -AutoDiscoverServiceInternalUri $null
                } else {
                    Get-ClientAccessServer $srv | Set-ClientAccessServer -AutoDiscoverServiceInternalUri $null
                }
            } else {
                Write-Host "[+] Configuring Autodiscover SCP Internal URI..." -ForegroundColor Yellow
                $targetScpDomain = if ($AutodiscoverURL) { $AutodiscoverURL } else { $InternalURL }
                $autoDiscoverUri = "https://$targetScpDomain/Autodiscover/Autodiscover.xml"

                if (Get-Command Set-ClientAccessService -ErrorAction SilentlyContinue) {
                    Get-ClientAccessService $srv | Set-ClientAccessService -AutoDiscoverServiceInternalUri $autoDiscoverUri
                } else {
                    Get-ClientAccessServer $srv | Set-ClientAccessServer -AutoDiscoverServiceInternalUri $autoDiscoverUri
                }
            }

            Write-Host "`n[✓] Successfully configured '$srv'.`n" -ForegroundColor Green
        }
    }
}

End {
    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host " [✓] Execution Complete!" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Cyan

    # Smart Post-Installation Recommendations & Health Tips
    Write-Host "`n[💡] Post-Installation Recommendations & Next Steps:" -ForegroundColor Magenta

    # 1. Send Connector check
    if (-not $CreateSendConnector) {
        $hasSendConnector = Get-SendConnector -ErrorAction SilentlyContinue | Where-Object { 
            $_.AddressSpaces | Where-Object { $_.Address -eq "*" }
        }
        if (-not $hasSendConnector) {
            Write-Host "  * Send Connector : No outbound Internet connector (SMTP:*) was detected." -ForegroundColor Yellow
            Write-Host "                     Tip: Rerun with '-CreateSendConnector' to automatically create one." -ForegroundColor DarkGray
        }
    }

    # 2. Message Size check
    if (-not $MaxMessageSize) {
        $currentLimit = (Get-TransportConfig -ErrorAction SilentlyContinue).MaxSendSize
        Write-Host "  * Message Limits : Current Transport limit is '$currentLimit'." -ForegroundColor Gray
        Write-Host "                     Tip: Rerun with '-MaxMessageSize 50MB' to increase limits across all connectors." -ForegroundColor DarkGray
    }

    # 3. SSL Certificate Binding Tip
    Write-Host "  * SSL Certificate: Ensure a valid third-party SSL certificate is assigned to IIS and SMTP services." -ForegroundColor Gray
    Write-Host "                     Command: Enable-ExchangeCertificate -Thumbprint <THUMBPRINT> -Services IIS,SMTP" -ForegroundColor DarkGray

    # 4. IIS Recycle Tip
    Write-Host "  * IIS Recycle    : If URL changes are not immediately visible in EAC/clients, run 'iisreset' or restart AppPools.`n" -ForegroundColor Gray
}
