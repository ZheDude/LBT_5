Rename-Computer -NewName "OfflineRootCA" -Force -Restart

Install-WindowsFeature -Name ADCS-Cert-Authority -IncludeManagementTools

# prepare CAPolicy.inf



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
RenewalValidityPeriodUnits=20
CRLPeriod=weeks
CRLPeriodUnits=26
CRLDeltaPeriod=Days
CRLDeltaPeriodUnits=0
LoadDefaultTemplates=0
AlternateSignatureAlgorithm=1
"@

$CAPolicy | Out-File -FilePath "C:\Windows\CAPolicy.inf" -Encoding ascii


WindowsFeature Adcs-Cert-Authority -IncludeManagementTools Install-AdcsCertificationAuthority –CAType StandaloneRootCA –CACommonName "MurbalRootCA" –KeyLength 2048 –HashAlgorithm SHA1 –CryptoProviderName "RSA#Microsoft Software Key Storage Provider"

certutil -setreg CA\CRLPublicationURLs "1:C:\Windows\system32\CertSrv\CertEnroll\%3%8.crl\n2:https://pki.corp.murbal.at/pki/%3%8.crl"

certutil –setreg CA\CACertPublicationURLs "2:https://pki.corp.murbal.at/pki/%1_%3%4.crt"

Certutil -setreg CA\CRLOverlapPeriodUnits 12

Certutil -setreg CA\CRLOverlapPeriod "Hours"

Certutil -setreg CA\ValidityPeriodUnits 10

Certutil -setreg CA\ValidityPeriod "Years"

certutil -setreg CA\DSConfigDN CN=Configuration,DC=corp,DC=murbal,DC=at

restart-service certsvc

certutil -crl