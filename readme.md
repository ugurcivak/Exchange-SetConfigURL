Exchange URL'lerini düzenlemenizi saðlar.

Standart Exchange kurulumu sonrasýnda mail alýþveriþinin saðlýlý çalýþmasý için gereklidir.

```sh

.ÖRNEK
.\SetExchangeURLs.ps1 -Server MB1 -InternalURL mail.maestropanel.com -ExternalURL mail.maestropanel.com


.ÖRNEK
.\SetExchangeURLs.ps1 -Server MB1,MB2 -InternalURL mail.maestropanel.com -ExternalURL mail.maestropanel.com


.ÖRNEK DAG
.\SetExchangeURLs.ps1 -Server MB1,MB2 -InternalURL mail.maestropanel.com -ExternalURL mail.maestropanel.com
```