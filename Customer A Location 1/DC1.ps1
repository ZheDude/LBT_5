Rename-Computer -NewName "DC1" -Force -Restart

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

$SiteName = "St.Poelten-Office"
$SiteLinkName = "SiteLink-Wien-HQ-St.Poelten-Office"
# Erstellen des neuen Standorts
New-ADReplicationSite -Name $SiteName
# Erstellen der SiteLinks
New-ADReplicationSiteLink -Name $SiteLinkName -SitesIncluded $DefaultSiteName,$SiteName -Cost 100 -ReplicationFrequencyInMinutes 15

# Konfiguration des Subnetzes für den neuen Standort