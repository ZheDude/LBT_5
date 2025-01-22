Rename-Computer -NewName "WinBalikciS1" -Force -Restart

# Warten auf Neustart (manuelle Wiederaufnahme erforderlich)
Write-Host "Neustart des Computers erforderlich. Bitte nach Neustart das Skript erneut ausführen."

# Netzwerk-Konfiguration
$IP = "192.168.0.10"
$SubnetMask = "255.255.255.0"
$Gateway = "192.168.0.254"
$InterfaceAlias = (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }).InterfaceAlias

Install-WindowsFeature -Name AD-Domain-Services, DNS, DHCP -IncludeManagementTools

# Active Directory Konfiguration
$DomainName = "corp.murbal.at"
$SafeModePassword = Read-Host -Prompt "Bitte das DSRM-Kennwort für den AD DS Safe Mode eingeben" -AsSecureString

Install-ADDSForest -DomainName $DomainName `
    -DomainNetBiosName "CORP" `
    -ForestMode "WinThreshold" `
    -DomainMode "WinThreshold" `
    -InstallDNS `
    -SafeModeAdministratorPassword $SafeModePassword `
    -Force

Rename-ADObject -Identity (Get-ADReplicationSite -Filter {Name -eq "Default-First-Site-Name"}).DistinguishedName -NewName "Standort1"
