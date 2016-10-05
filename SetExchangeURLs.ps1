<#
.ÖZET
SetExchangeURLs.ps1

.AÇIKLAMA
Powershell scripti ile Exchange Server 2013/2016, CAS URL kayıtlarını basitçe yapılandırılabilir. 

Servisler için farklı alan adları/uzantısı kullanıyorsanız uygulamaz ve hata verir.

.PARAMETRE Server
Yapılandırma yapılacak sunucu(lar) adı.

.PARAMETRE InternalURL
Kullanılacak Internal alan bilgisi.

.PARAMETRE ExternalURL
Kullanılacak External alan bilgisi.

.ÖRNEK
.\SetExchangeURLs.ps1 -Server MB1 -InternalURL mail.maestropanel.com -ExternalURL mail.maestropanel.com

.ÖRNEK
.\SetExchangeURLs.ps1 -Server MB1,MB2 -InternalURL mail.maestropanel.com -ExternalURL mail.maestropanel.com

.ÖRNEK DAG
.\SetExchangeURLs.ps1 -Server MB1,MB2 -InternalURL mail.maestropanel.com -ExternalURL mail.maestropanel.com

.URL
https://wiki.maestropanel.com/powershell-script-ile-exchange-internalexternal-url

.EK BİLGİ

Yazar: Uğur CIVAK
Yazar: #Clone

Daha fazla bilgi için,

* Website: https://www.maestropanel.com
* Website: https://www.sistemduragi.com

* Twitter: https://twitter.com/maestropanel
* Twitter: https://twitter.com/ugurcivaks
#>

###########
###Script##
###########

[CmdletBinding()]
param(
	[Parameter( Position=0,Mandatory=$true)]
	[string[]]$Server,

	[Parameter( Mandatory=$true)]
	[string]$InternalURL,

	[Parameter( Mandatory=$true)]
    [AllowEmptyString()]
	[string]$ExternalURL,

    [Parameter( Mandatory=$false)]
    [string]$DefaultAuth="NTLM",

    [Parameter( Mandatory=$false)]
    [Boolean]$InternalSSL=$true,

    [Parameter( Mandatory=$false)]
    [Boolean]$ExternalSSL=$true
	)


#...................................
# Script
#...................................

Begin {

    #Exchange Oturum Hazırlanıyor.
    if (Test-Path $env:ExchangeInstallPath\bin\RemoteExchange.ps1)
    {
	    . $env:ExchangeInstallPath\bin\RemoteExchange.ps1
	    Connect-ExchangeServer -auto -AllowClobber
    }
    else
    {
        Write-Warning "Exchange Server Management Tools kurulu değil."
        EXIT
    }
}

Process {

    foreach ($i in $server)
    {
        if ((Get-ExchangeServer $i -ErrorAction SilentlyContinue).IsClientAccessServer)
        {
            Write-Host "----------------------------------------"
            Write-Host " Yapılandırmalar $i üzerinde gerçekleşecek."
            Write-Host "----------------------------------------`r`n"
            Write-Host "Yapılandırmalar:"
            Write-Host " - Internal URL: $InternalURL olarak yapılandırılacak"
            Write-Host " - External URL: $ExternalURL olarak yapılandırılacak"
            Write-Host " - Outlook Anywhere yetkilendirme : $Auth olarak yapılandırılacak"
            Write-Host "`r`n"

            Write-Host "Outlook Anywhere URL yapılandırılıyor"
            Get-OutlookAnywhere -Server $i | Set-OutlookAnywhere -ExternalHostname $externalurl -InternalHostname $internalurl -ExternalClientsRequireSsl $ExternalSSL -InternalClientsRequireSsl $InternalSSL -DefaultAuthenticationMethod $DefaultAuth

            if ($externalurl -eq "")
            {
                Write-Host "Outlook Web App URL yapılandırılıyor"
                Get-OwaVirtualDirectory -Server $i | Set-OwaVirtualDirectory -ExternalUrl $null -InternalUrl https://$internalurl/owa

                Write-Host "Exchange Control Panel URL yapılandırılıyor"
                Get-EcpVirtualDirectory -Server $i | Set-EcpVirtualDirectory -ExternalUrl $null -InternalUrl https://$internalurl/ecp

                Write-Host "ActiveSync URL yapılandırılıyor"
                Get-ActiveSyncVirtualDirectory -Server $i | Set-ActiveSyncVirtualDirectory -ExternalUrl $null -InternalUrl https://$internalurl/Microsoft-Server-ActiveSync

                Write-Host "Configuring Exchange Web Services URL yapılandırılıyor"
                Get-WebServicesVirtualDirectory -Server $i | Set-WebServicesVirtualDirectory -ExternalUrl $null -InternalUrl https://$internalurl/EWS/Exchange.asmx

                Write-Host "Configuring Offline Address Book URL yapılandırılıyor"
                Get-OabVirtualDirectory -Server $i | Set-OabVirtualDirectory -ExternalUrl $null -InternalUrl https://$internalurl/OAB

                Write-Host "Configuring MAPI/HTTP URL yapılandırılıyor"
                Get-MapiVirtualDirectory -Server $i | Set-MapiVirtualDirectory -ExternalUrl $null -InternalUrl https://$internalurl/mapi
            }
            else
            {
                Write-Host "Outlook Web App URL yapılandırılıyor"
                Get-OwaVirtualDirectory -Server $i | Set-OwaVirtualDirectory -ExternalUrl https://$externalurl/owa -InternalUrl https://$internalurl/owa

                Write-Host "Exchange Control Panel URL yapılandırılıyor"
                Get-EcpVirtualDirectory -Server $i | Set-EcpVirtualDirectory -ExternalUrl https://$externalurl/ecp -InternalUrl https://$internalurl/ecp

                Write-Host "ActiveSync URL yapılandırılıyor"
                Get-ActiveSyncVirtualDirectory -Server $i | Set-ActiveSyncVirtualDirectory -ExternalUrl https://$externalurl/Microsoft-Server-ActiveSync -InternalUrl https://$internalurl/Microsoft-Server-ActiveSync

                Write-Host "Exchange Web Services URL yapılandırılıyor"
                Get-WebServicesVirtualDirectory -Server $i | Set-WebServicesVirtualDirectory -ExternalUrl https://$externalurl/EWS/Exchange.asmx -InternalUrl https://$internalurl/EWS/Exchange.asmx

                Write-Host "Offline Address Book URL yapılandırılıyor"
                Get-OabVirtualDirectory -Server $i | Set-OabVirtualDirectory -ExternalUrl https://$externalurl/OAB -InternalUrl https://$internalurl/OAB

                Write-Host "MAPI/HTTP URL yapılandırılıyor"
                Get-MapiVirtualDirectory -Server $i | Set-MapiVirtualDirectory -ExternalUrl https://$externalurl/mapi -InternalUrl https://$internalurl/mapi
            }



            Write-Host "Autodiscover yapılandırılıyor"
            Get-ClientAccessServer $i | Set-ClientAccessServer -AutoDiscoverServiceInternalUri https://$internalurl/Autodiscover/Autodiscover.xml

            Write-Host "`r`n"
        }
        else
        {
            Write-Host -ForegroundColor Yellow "$i Client Access server değil."
        }
    }
}

End {

    Write-Host "İşlemler tamamlandı."
    Write-Host "Detaylı bilgi, https://wiki.maestropanel.com/powershell-script-ile-exchange-internalexternal-url"

}

#...................................
# Finished
#...................................