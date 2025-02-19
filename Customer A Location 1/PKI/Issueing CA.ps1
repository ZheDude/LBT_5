Rename-Computer -NewName "HQ-ICA" -Force -Restart

# IP Konfiguration
$IP = "192.168.0.12"
$SubnetMask = "255.255.255.0"
$Gateway = "192.168.0.254"
$InterfaceAlias = (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }).InterfaceAlias

New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IP -PrefixLength 24 -DefaultGateway $Gateway
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses ("192.168.0.10")

$DomainName = "corp.murbal.at"
$DomainCreds = Get-Credential -Message "Bitte die Anmeldeinformationen eines Domänenadministrators eingeben"
Add-Computer -DomainName $DomainName -Credential $DomainCreds -Restart


certutil –dspublish –f orca1_ContosoRootCA.crt RootCA 
certutil –addstore –f root orca1_ContosoRootCA.crt 
certutil –addstore –f root ContosoRootCA.crl
