Rename-Computer -NewName "HQ-CA" -Force -Restart

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

Install-WindowsFeature -Name AD-Certificate -IncludeManagementTools
Install-WindowsFeature -Name Web-Server, Web-WebServer, Web-Common-Http, Web-Default-Doc, Web-Static-Content, Web-Dir-Browsing, Web-Http-Errors -IncludeManagementTools


$CAPolicy = @"
[Version]
Signature="$Windows NT$"
[PolicyStatementExtension]
Policies=InternalPolicy
[InternalPolicy]
OID= 1.2.3.4.1455.67.89.5
Notice="Legal Policy Statement"
URL=http://pki.corp.murbal.at/cps.txt
[Certsrv_Server]
RenewalKeyLength=2048
RenewalValidityPeriod=Years
RenewalValidityPeriodUnits=10
LoadDefaultTemplates=0
AlternateSignatureAlgorithm=1
"@


$CAPolicy | Out-File -FilePath "C:\Windows\CAPolicy.inf" -Encoding ascii

Certutil -setreg CA\CRLPeriodUnits 1
Certutil -setreg CA\CRLPeriod "Weeks"
Certutil -setreg CA\CRLDeltaPeriodUnits 1
Certutil -setreg CA\CRLDeltaPeriod "Days"
Certutil -setreg CA\CRLOverlapPeriodUnits 12
Certutil -setreg CA\CRLOverlapPeriod "Hours"
# Zertifikatgültigkeit
Certutil -setreg CA\ValidityPeriodUnits 10
Certutil -setreg CA\ValidityPeriod "Years"
Certutil -setreg CA\AuditFilter 127

certutil -setreg CA\CACertPublicationURLs "1:C:\Windows\system32\CertSrv\CertEnroll\%1_%3%4.crt\n2:ldap:///CN=%7,CN=AIA,CN=Public Key Services,CN=Services,%6%11\n2:http://pki.corp.murbal.at/CertEnroll/%1_%3%4.crt"

certutil -setreg CA\CACertPublicationURLs "1:C:\Windows\system32\CertSrv\CertEnroll\%1_%3%4.crt\n2:ldap:///CN=%7,CN=AIA,CN=Public Key Services,CN=Services,%6%11\n2:http://pki.fabrikam.com/CertEnroll/%1_%3%4.crt"

certutil -setreg CA\CRLPublicationURLs "65:C:\Windows\system32\CertSrv\CertEnroll\%3%8%9.crl\n79:ldap:///CN=%7%8,CN=%2,CN=CDP,CN=Public Key Services,CN=Services,%6%10\n6:http://pki.corp.murbal.at/CertEnroll/%3%8%9.crl\n65:file://\\HQ-CA.corp.murbal.at\CertEnroll\%3%8%9.crl"

certutil -setreg CA\CRLPublicationURLs "65:C:\Windows\system32\CertSrv\CertEnroll\%3%8%9.crl\n79:ldap:///CN=%7%8,CN=%2,CN=CDP,CN=Public Key Services,CN=Services,%6%10\n6:http://pki.fabrikam.com/CertEnroll/%3%8%9.crl\n65:file://\\Srv1.fabrikam.com\CertEnroll\%3%8%9.crl"

cd C:\Windows\system32\CertSrv\CertEnroll
copy .\HQ-CA.corp.murbal.at_corp-HQ-CA-CA.crt C:\pki

restart-service certsvc
certutil -crl
#result:
CertUtol: -CRL command FAILED: 0x800706ba (WIN32: 1722 RPC_S_SERVER_UNAVAILABLE)
CertUtil: The RPC server is unavailable.