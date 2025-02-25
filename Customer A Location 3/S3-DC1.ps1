Rename-Computer -NewName "S3-DC1" -Force -Restart

# Warten auf Neustart (manuelle Wiederaufnahme erforderlich)
Write-Host "Neustart des Computers erforderlich. Bitte nach Neustart das Skript erneut ausführen."

# Netzwerk-Konfiguration
$IP = "192.168.1.10"
$SubnetMask = "255.255.255.0"
$Gateway = "192.168.1.1"
$InterfaceAlias = (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }).InterfaceAlias

New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IP -PrefixLength 24 -DefaultGateway $Gateway
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses ("192.168.0.10")

Install-WindowsFeature -Name AD-Domain-Services, DNS, DHCP -IncludeManagementTools


Install-ADDSDomainController `
-NoGlobalCatalog:$false `
-CreateDnsDelegation:$false `
-Credential (Get-Credential) `
-CriticalReplicationOnly:$false `
-DatabasePath "C:\Windows\NTDS" `
-DomainName "corp.murbal.at" `
-InstallDns:$true `
-LogPath "C:\Windows\NTDS" `
-NoRebootOnCompletion:$false `
-ReplicationSourceDC "HQ-DC1.corp.murbal.at" `
-SiteName "Linz-Office" `
-SysvolPath "C:\Windows\SYSVOL" `
-Force:$true
