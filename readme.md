Exchange URL'lerini düzenlemenizi sağlar.!

Standart Exchange kurulumu sonrasında mail alışverişinin sağlıklı çalışmasını sağlar.

[Exchange2016]({{site.baseurl}}//Exchange%202016.png)

**Örnek**
```sh
.ÖRNEK
.\SetExchangeURLs.ps1 -Server MB1 -InternalURL mail.maestropanel.com -ExternalURL mail.maestropanel.com
.ÖRNEK Multiple
.\SetExchangeURLs.ps1 -Server MB1,MB2 -InternalURL mail.maestropanel.com -ExternalURL mail.maestropanel.com
.ÖRNEK DAG
.\SetExchangeURLs.ps1 -Server MB1,MB2 -InternalURL mail.maestropanel.com -ExternalURL mail.maestropanel.com
```

**Neleri düzenler?**
- "NTLM" *Varsayılan yetkilendirme
- "Outlook Web App URL"
- "Exchange Kontrol Panel URL"
- "ActiveSync URL"
- "Exchange Web Servisleri URL"
- "Çevrimdışı Address Defteri URL"
- "MAPI/HTTP URL"
- "Autodiscover URL"


**Diğer**

_Destek_
- Exchange Server 2016
- Exchange Server 2013
- Exchange Server 2010 SP2 & SP3 (CAS üzerinde)

_Kaynak_
-[_Powershell Script ile Exchange Server Internal & External URL Yapılandırma_](https://wiki.maestropanel.com/powershell-script-ile-exchange-server-internal-external-url-yapilandirma "Powershell Exchange Script")
-[Configure Exchange 2016 external URLs](https://technet.microsoft.com/en-us/library/mt441781(v=exchg.150).aspx)
-[Configure Exchange 2016 internal URLs](https://technet.microsoft.com/en-us/library/mt441779(v=exchg.150).aspx)