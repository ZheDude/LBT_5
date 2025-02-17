Rename-Computer -NewName "DC1" -Force -Restart

# Warten auf Neustart (manuelle Wiederaufnahme erforderlich)
Write-Host "Neustart des Computers erforderlich. Bitte nach Neustart das Skript erneut ausführen."

# Netzwerk-Konfiguration
$IP = "192.168.0.10"
$SubnetMask = "255.255.255.0"
$Gateway = "192.168.0.254"
$InterfaceAlias = (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }).InterfaceAlias

New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IP -PrefixLength 24 -DefaultGateway $Gateway
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses ("192.168.0.10")

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


# Standort-Konfiguration
$DefaultSiteName  = "Wien-HQ"
Rename-ADObject -Identity (Get-ADReplicationSite -Filter {Name -eq "Default-First-Site-Name"}).DistinguishedName -NewName $DefaultSiteName
## Erstellung: Standort 2
$SiteName = "Linz-Office"
$SiteLinkName = "SiteLink-Wien-HQ-Linz-Office"
# Erstellen des neuen Standorts
New-ADReplicationSite -Name $SiteName
# Erstellen der SiteLinks
New-ADReplicationSiteLink -Name $SiteLinkName -SitesIncluded $DefaultSiteName,$SiteName -Cost 100 -ReplicationFrequencyInMinutes 15
New-ADReplicationSubnet -Name "192.168.1.0/24" -Site $SiteName

$SiteName = "St-Poelten-Office"
$SiteLinkName = "SiteLink-Wien-HQ-St-Poelten-Office"
# Erstellen des neuen Standorts
New-ADReplicationSite -Name $SiteName
# Erstellen der SiteLinks
New-ADReplicationSiteLink -Name $SiteLinkName -SitesIncluded $DefaultSiteName,$SiteName -Cost 100 -ReplicationFrequencyInMinutes 15
New-ADReplicationSubnet -Name "172.16.0.0/24" -Site $SiteName

# DNS-Konfiguration:
$InterfaceAlias = (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }).InterfaceAlias
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses ("192.168.0.10", "192.168.0.11")

Add-DnsServerPrimaryZone -Name "corp.murbal.at" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "192.168.0.0/24" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "192.168.1.0/24" -ReplicationScope "Forest"
Add-DnsServerPrimaryZone -NetworkID "172.16.0.0/24" -ReplicationScope "Forest"

Add-DnsServerResourceRecordPtr -Name "10" `
    -ZoneName "0.168.192.in-addr.arpa" `
    -PtrDomainName "DC1.corp.murbal.at" `
    -ComputerName DC1.corp.5cn.at

Add-DnsServerResourceRecordPtr -Name "11" `
    -ZoneName "0.168.192.in-addr.arpa" `
    -PtrDomainName "DC2.corp.murbal.at" `
    -ComputerName DC1.corp.5cn.at


$IP = "192.168.0.10"
$Hostname = "DC1"
Add-DhcpServerInDc -DnsName $Hostname -IPAddress $IP

# Erstellen eines DHCP-Scopes für das Subnetz 192.168.0.0/24
$ScopeName = "LAN-HQ-Scope"
$StartRange = "192.168.0.1"
$EndRange = "192.168.0.254"
$ExcludedStart = "192.168.0.1"
$ExcludedEnd = "192.168.0.20"
$SubnetMask = "255.255.255.0"
$Gateway = "192.168.0.254"
$DnsServers = "192.168.0.10","192.168.0.11"

Add-DhcpServerv4Scope -Name $ScopeName -StartRange $StartRange -EndRange $EndRange -SubnetMask $SubnetMask -State Active
Add-DhcpServerv4ExclusionRange -ScopeId "192.168.0.0" -StartRange $ExcludedStart -EndRange $ExcludedEnd
Add-DhcpServerv4ExclusionRange -ScopeId "192.168.0.0" -StartRange $Gateway -EndRange $Gateway
Set-DhcpServerv4OptionValue -ScopeId "192.168.0.0" -OptionId 3 -Value $Gateway
Set-DhcpServerv4OptionValue -ScopeId "192.168.0.0" -OptionId 6 -Value $DnsServers

Write-Host "Konfiguration abgeschlossen."


# DHCP Failover konfigurieren#
$PrimaryDHCP = "DC1.corp.murbal.at"
$SecondaryDHCP = "DC2.corp.murbal.at"
$ScopeId = "192.168.0.0"
$FailoverName = "Failover-HQ"

Add-DhcpServerv4Failover -ComputerName $PrimaryDHCP -Name `
$FailoverName -PartnerServer $SecondaryDHCP -ScopeId $ScopeId `
 -LoadBalancePercent 50 -MaxClientLeadTime 2:00:00 -AutoStateTransition $True -StateSwitchInterval 2:00:00

# OU Struktur
$OUName = "HQ"
$OUPath = "DC=corp,DC=murbal,DC=at"
New-ADOrganizationalUnit -Name $OUName -Path "DC=corp,DC=murbal,DC=at"

# GPO - Konfigurationen
# 1. GPO welches den Desktop Hintergrund Bild festlegt
$GPOName = "Desktop Bild"
$GPOPath = "OU=HQ,DC=corp,DC=murbal,DC=at"
$GPODescription = "Setzt den Desktop Hintergrund"
$GPODisplayName = "Desktop Hintergrund"
$GPOValue = "C:\Windows\Web\Wallpaper\Windows10.jpg"
$GPOValueName = "DesktopBackground"
$GPOValuePath = "Desktop"
$GPOValueProperty = "WallpaperStyle"
$GPOValueData = "0"
$GPOValueProperty2 = "TileWallpaper"
$GPOValueData2 = "0"

New-GPO -Name $GPOName -Comment $GPODescription -Domain $DomainName
New-GPLink -Name $GPOName -Target $GPOPath
Set-GPRegistryValue -Name $GPOName -Key $GPOValuePath -ValueName $GPOValueName -Type String -Value $GPOValue
Set-GPRegistryValue -Name $GPOName -Key $GPOValuePath -ValueName $GPOValueProperty -Type String -Value $GPOValueData
Set-GPRegistryValue -Name $GPOName -Key $GPOValuePath -ValueName $GPOValueProperty2 -Type String -Value $GPOValueData2


# 2. GPO welches den Sperrbildschirm festlegt
$GPOName2 = "Sperrbildschirm"
$GPOPath2 = "OU=HQ,DC=corp,DC=murbal,DC=at"
$GPODescription2 = "Setzt den Sperrbildschirm"
$GPODisplayName2 = "Sperrbildschirm"
$GPOValue2 = "C:\Windows\Web\Wallpaper\Windows10.jpg"
$GPOValueName2 = "LockScreenImage"
$GPOValuePath2 = "Desktop"
$GPOValueProperty2 = "LockScreenImage"
$GPOValueData2 = "C:\Windows\Web\Wallpaper\Windows10.jpg"

