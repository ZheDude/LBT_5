Rename-Computer -NewName "HQ-DC1" -Force -Restart

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
    -PtrDomainName "HQ-DC1.corp.murbal.at" `
    -ComputerName HQ-DC1.corp.murbal.at

Add-DnsServerResourceRecordPtr -Name "11" `
    -ZoneName "0.168.192.in-addr.arpa" `
    -PtrDomainName "HQ-DC2.corp.murbal.at" `
    -ComputerName HQ-DC1.corp.murbal.at

# PKi DNS CName
$CName = "pki.corp.murbal.at"
$CNameTarget = "HQ-ICA.corp.murbal.at"
Add-DnsServerResourceRecordCName -Name $CName -HostNameAlias $CNameTarget -ZoneName "corp.murbal.at"

$IP = "192.168.0.10"
$Hostname = "HQ-DC1"
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


# DHCP Failover konfigurieren
$PrimaryDHCP = "HQ-DC1.corp.murbal.at"
$SecondaryDHCP = "HQ-DC2.corp.murbal.at"
$ScopeId = "192.168.0.0"
$FailoverName = "Failover-HQ"

Add-DhcpServerv4Failover -ComputerName $PrimaryDHCP -Name `
$FailoverName -PartnerServer $SecondaryDHCP -ScopeId $ScopeId `
 -LoadBalancePercent 50 -MaxClientLeadTime 2:00:00 -AutoStateTransition $True -StateSwitchInterval 2:00:00

# OU Struktur
$OUName = "HQ"
$OUPath = "DC=corp,DC=5cn,DC=at"
New-ADOrganizationalUnit -Name $OUName -Path $OUPath
$OUPath = "OU=HQ,DC=corp,DC=5cn,DC=at"
$OUName = "Users"
New-ADOrganizationalUnit -Name $OUName -Path $OUPath
$OUName = "Groups"
New-ADOrganizationalUnit -Name $OUName -Path $OUPath


# Radius User and Groups
$GroupName = "Net-Admins"
$GroupDescription = "Netzwerk Administratoren"
$GroupPath = "OU=Groups,OU=HQ,DC=corp,DC=murbal,DC=at"
New-ADGroup -Name $GroupName -Description $GroupDescription -Path $GroupPath -GroupCategory Security -GroupScope Global

$UserName = "NetAdmin"
$UserDescription = "Netzwerk Administrator"
$UserPath = "OU=Users,OU=HQ,DC=corp,DC=murbal,DC=at"
$UserPassword = Read-Host -Prompt "Bitte das Kennwort für den Benutzer eingeben" -AsSecureString
New-ADUser -Name $UserName -Description $UserDescription -Path $UserPath -AccountPassword $UserPassword -ChangePasswordAtLogon $True -Enabled $True

## Gruppenmitgliedschaft
Add-ADGroupMember -Identity $GroupName -Members $UserName

## Benutzer akivieren
Enable-ADAccount -Identity $UserName


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


# AGDLP
# Erstellen der OUs 
$fullPath = "OU=HQ,DC=corp,DC=murbal,DC=at"
$departments = @("IT", "Marketing", "Sales", "Production", "HR") 
foreach ($dept in $departments) { 
    New-ADOrganizationalUnit -Name $dept -Path $fullPath 
} 
# Benutzer erstellen 
$users = @( 
    @{Name="Max Mustermann"; Dept="IT"; Role="Manager"}, 
    @{Name="Lisa Müller"; Dept="Marketing"; Role="Manager"}, 
    @{Name="Tom Schmidt"; Dept="Sales"; Role="Manager"}, 
    @{Name="Anna Schulz"; Dept="Production"; Role="Manager"}, 
    @{Name="Erik Hoffmann"; Dept="HR"; Role="Manager"}, 
    @{Name="Julia Fischer"; Dept="IT"; Role="Staff"}, 
    @{Name="Mark Weber"; Dept="Marketing"; Role="Staff"}, 
    @{Name="Sarah Wagner"; Dept="Sales"; Role="Staff"}, 
    @{Name="Paul Becker"; Dept="Production"; Role="Staff"}, 
    @{Name="Laura Schäfer"; Dept="HR"; Role="Staff"}, 
    @{Name="Jonas Bauer"; Dept="IT"; Role="Staff"}, 
    @{Name="Nina Krause"; Dept="Marketing"; Role="Staff"}, 
    @{Name="Leon Richter"; Dept="Sales"; Role="Staff"}, 
    @{Name="Mia Wolf"; Dept="Production"; Role="Staff"}, 
    @{Name="Felix Neumann"; Dept="HR"; Role="Staff"} 
) 

foreach ($user in $users) { 
    $ouPath = "OU=$($user.Dept),$($fullPath)" 
    $username = $user.Name -replace "\s", "" 
    New-ADUser -Name $user.Name -GivenName ($user.Name.Split()[0]) -Surname ($user.Name.Split()[1]) -SamAccountName $username -UserPrincipalName "$username@corp.murbal.at" -Path $ouPath -AccountPassword (ConvertTo-SecureString "SuperGeheim123!" -AsPlainText -Force) -Enabled $true
} 

# Erstellen der Global Security Groups 
$roles = @("Manager", "Staff") 
foreach ($dept in $departments) { 
    foreach ($role in $roles) { 
        New-ADGroup -Name "Role_$dept-$role" -GroupScope Global -Path "OU=$dept,$fullPath" 
    } 
} 

# Benutzer zu den Global Groups hinzufügen 
foreach ($user in $users) { 
    $username = $user.Name -replace "\s", "" 
    Add-ADGroupMember -Identity "Role_$($user.Dept)-$($user.Role)" -Members $username 
} 

# Erstellen der Domain-Local Groups für Fileshare Berechtigungen 
foreach ($dept in $departments) { 
    New-ADGroup -Name "DL_$dept-Docs_Read" -GroupScope DomainLocal -Path "OU=$dept,$fullPath" 
    New-ADGroup -Name "DL_$dept-Docs_Write" -GroupScope DomainLocal -Path "OU=$dept,$fullPath" 
    New-ADGroup -Name "DL_$dept-Docs_Modify" -GroupScope DomainLocal -Path "OU=$dept,$fullPath" 
} 

# Global Groups zu den Domain-Local Groups hinzufügen 
foreach ($dept in $departments) { 
    $cn_read = Get-ADGroup -Identity "DL_${dept}-Docs_Read" | Select DistinguishedName 
    $cn_write = Get-ADGroup -Identity "DL_${dept}-Docs_Write" | Select DistinguishedName 
    $cn_modify = Get-ADGroup -Identity "DL_${dept}-Docs_Modify" | Select DistinguishedName 
    Add-ADGroupMember -Identity $cn_read -Members "Role_${dept}-Staff" 
    Add-ADGroupMember -Identity $cn_write -Members "Role_${dept}-Staff" 
    Add-ADGroupMember -Identity $cn_modify -Members "Role_${dept}-Manager" 
} 


# DFS Konfiguration
Install-WindowsFeature -Name FS-DFS-Namespace, FS-DFS-Replication, RSAT-DFS-Mgmt-Con -IncludeManagementTools

# GPO DFS mount
$GPOName = "DFS-Mount"
$GPOPath = "OU=HQ,DC=corp,DC=murbal,DC=at"
$GPODescription = "Mountet das DFS Share"