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
write-output "Example CPS statement" | out-file c:\pki\cps.txt
New-smbshare -name $shareName $folderPath -FullAccess SYSTEM,"CORP\Domain Admins" -ChangeAccess $domainGroup

# IIS Starten
# Neues Virtual Directory erstellen: pki | C:\pki
# Anonymes Zugriff aktivieren
# - Connections -> Default Web Site -> pki -> Authentication -> Security -> Permissions for pki -> Add -> Users, Computers, Service Accounts or Groups `
# -> Cert Publishers -> OK
# - Connections -> Default Web Site -> pki -> Authentication -> Security -> Permissions for pki -> Add -> Users, Computers, Service Accounts or Groups `
# -> Object Types -> Service Accounts -> OK
# - Connections -> Default Web Site -> pki -> Authentication -> Security -> Permissions for pki -> Add -> Users, Computers, Service Accounts or Groups `
# -> Locations -> HQ-ICA -> OK
# On Permissions for pki select Cert Publishers (CORP\Cert Publishers). Under Permissions for Cert Publishers, select the Modify checkbox in the Allow column and then click OK twice.
# In the pki Home pane, double-click Request Filtering.
# The File Name Extensions tab is selected by default in the Request Filtering pane. In the Actions pane, click Edit Feature Settings.
# In Edit Request Filtering Settings, select Allow double escaping and then click OK. Close Internet Information Services (IIS) Manager.
# Run Windows PowerShell as an administrator. From Windows PowerShell, run the command iisreset


# HQ-ICA als Subordinate CA konfigurieren

$CAPolicy = @"
[Version]
Signature="$Windows NT$"
[PolicyStatementExtension]
Policies=InternalPolicy
[InternalPolicy]
OID= 1.2.3.4.1455.67.89.5
Notice="Legal Policy Statement"
URL=https://pki.corp.murbal.at/pki/cps.txt
[Certsrv_Server]
RenewalKeyLength=2048
RenewalValidityPeriod=Years
RenewalValidityPeriodUnits=5
LoadDefaultTemplates=0
AlternateSignatureAlgorithm=1
"@

$CAPolicy | Out-File -FilePath "C:\\CAPolicy.inf" -Encoding ascii


gpupdate /force

Install-WindowsFeature -Name AD-Certificate -IncludeManagementTools

# Open the AD CS Configuration Wizard:
# Select Rolte Certificate Authority
# Select Enterprise CA
# Select Subordinate CA
# Create a new private key
# Cryptographic service provider: RSA#Microsoft Software Key Storage Provider
# Key length: 2048
# Hash algorithm: SHA1
# CA Name: HQ-ICA
# Certificate Request: Save the request to a file on the target machine

Add-WindowsFeature Adcs-Cert-Authority -IncludeManagementTools Install-AdcsCertificationAuthority -CAType EnterpriseSubordinateCA -CACommonName "corp-HQ-ICA-CA" -KeyLength 2048 -HashAlgorithm SHA1 -CryptoProviderName "RSA#Microsoft Software Key Storage Provider"

# on Offline Root CA:
certreq -submit C:\HQ-ICA.corp.murbal.at_corp-HQ-ICA-CA.req

#result:
# RequestId: 2
# RequestId: "2"
# Certificate request is pending: Taken Under Submission (0)

# on Offline Root CA:
certutil -resubmit 2
certreq -retrieve 2 C:\HQ-ICA.corp.murbal.at_corp-HQ-ICA-CA.crt

# on HQ-ICA:
certutil -installcert C:\HQ-ICA.corp.murbal.at_corp-HQ-ICA-CA.crt
start-service certsvc
copy c:\Windows\system32\certsrv\certenroll\*.cr* c:\pki\


# AIA und CDP konfigurieren
certutil -setreg CA\CRLPublicationURLs "1:C:\Windows\system32\CertSrv\CertEnroll\%3%8.crl\n2:https://pki.corp.murbal.at/pki/%3%8.crl"
certutil -setreg CA\CACertPublicationURLs "2:https://pki.corp.murbal.at/pki/%1_%3%4.crt\n1:file://\\HQ-ICA.corp.murbal.at\pki\%1_%3%4.crt"
Certutil -setreg CA\CRLPeriodUnits 2
Certutil -setreg CA\CRLPeriod "Weeks"
Certutil -setreg CA\CRLDeltaPeriodUnits 1
Certutil -setreg CA\CRLDeltaPeriod "Days"
Certutil -setreg CA\CRLOverlapPeriodUnits 12
Certutil -setreg CA\CRLOverlapPeriod "Hours"
Certutil -setreg CA\ValidityPeriodUnits 5
Certutil -setreg CA\ValidityPeriod "Years"

restart-service certsvc
