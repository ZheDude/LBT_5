# Setzen des Hostnamens und Neustart für Änderung
Rename-Computer -NewName "HQ-DC2" -Force -Restart

# Warten auf Neustart (Skript nach Neustart erneut ausführen)
Write-Host "Computer wird neu gestartet. Nach dem Neustart bitte das Skript erneut ausführen."

# Netzwerk-Konfiguration
$IP = "192.168.0.11"
$SubnetMask = "255.255.255.0"
$Gateway = "192.168.0.254"
$InterfaceAlias = (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }).InterfaceAlias

New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IP -PrefixLength 24 -DefaultGateway $Gateway
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses ("192.168.0.10")

# Installieren der AD DS, DNS, und DHCP Rollen und Management-Tools
Install-WindowsFeature -Name AD-Domain-Services, DNS, DHCP -IncludeManagementTools

# Konfiguration des RODC
$DomainName = "corp.murbal.at"
$SafeModePassword = Read-Host -Prompt "Bitte das DSRM-Kennwort für den AD DS Safe Mode eingeben" -AsSecureString

Install-ADDSDomainController -DomainName $DomainName `
    -InstallDNS `
    -Credential (Get-Credential) `
    -SafeModeAdministratorPassword $SafeModePassword `
    -ReplicationSourceDC HQ-DC1.corp.murbal.at