Rename-Computer -NewName "S2-DC2" -Force -Restart

# Warten auf Neustart (manuelle Wiederaufnahme erforderlich)
Write-Host "Neustart des Computers erforderlich. Bitte nach Neustart das Skript erneut ausführen."

# Netzwerk-Konfiguration
$IP = "172.16.0.11"
$SubnetMask = "255.255.255.0"
$Gateway = "172.16.0.254"
$InterfaceAlias = (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }).InterfaceAlias

New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IP -PrefixLength 24 -DefaultGateway $Gateway
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses ("192.168.0.10")

Install-WindowsFeature -Name AD-Domain-Services, DNS, DHCP -IncludeManagementTools

# AD DC Join
$DomainName = "corp.murbal.at"
$SafeModePassword = Read-Host -Prompt "Bitte das DSRM-Kennwort für den AD DS Safe Mode eingeben" -AsSecureString
$SiteName = "St-Poelten-Office"
Install-ADDSDomainController -DomainName $DomainName `
    -SiteName $SiteName `
    -InstallDns `
    -Credential (Get-Credential) `
    -SafeModeAdministratorPassword $SafeModePassword `
    -Force:$true
    