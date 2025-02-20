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


certutil -dspublish -f OfflineRootCA_MurbalRootCA.crt  RootCA 
certutil -addstore -f root OfflineRootCA_MurbalRootCA.crt 
certutil -addstore -f root MurbalRootCA.crl



Install-WindowsFeature -Name Web-Server, Web-WebServer, Web-Common-Http, Web-Default-Doc, Web-Static-Content, Web-Dir-Browsing, Web-Http-Errors -IncludeManagementTools


$folderPath = "C:\pki"
$shareName = "pki"
$domainGroup = "CORP\Cert Publishers"

if (!(Test-Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory
    Write-Host "Folder 'pki' created at C:\."
} else {
    Write-Host "Folder 'pki' already exists."
}

New-smbshare -name $shareName $folderPath -FullAccess SYSTEM,"CORP\Domain Admins" -ChangeAccess $domainGroup

# IIS Starten
# Neues Virtual Directory erstellen
# 
