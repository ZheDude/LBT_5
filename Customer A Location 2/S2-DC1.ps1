Rename-Computer -NewName "S2-DC1" -Force -Restart

# Warten auf Neustart (manuelle Wiederaufnahme erforderlich)
Write-Host "Neustart des Computers erforderlich. Bitte nach Neustart das Skript erneut ausführen."

# Netzwerk-Konfiguration
$IP = "172.16.0.10"
$SubnetMask = "255.255.255.0"
$Gateway = "172.16.0.254"
$InterfaceAlias = (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }).InterfaceAlias

New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IP -PrefixLength 24 -DefaultGateway $Gateway
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses ("192.168.0.10")

Install-WindowsFeature -Name AD-Domain-Services, DNS, DHCP -IncludeManagementTools


$SafeModePassword = Read-Host -Prompt "Bitte das DSRM-Kennwort für den AD DS Safe Mode eingeben" -AsSecureString
$SiteName = "St-Poelten-Office"
Install-ADDSDomain -NewDomainName "sub" `
    -ParentDomainName "corp.murbal.at" `
    -InstallDNS `
    -SafeModeAdministratorPassword $SafeModePassword `
    -DomainType ChildDomain `
    -DomainMode "WinThreshold" `
    -SiteName $SiteName `
    -Credential (Get-Credential)

    