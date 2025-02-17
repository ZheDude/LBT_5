Rename-Computer -NewName "OfflineRootCA" -Force -Restart

New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress "192.168.10.11" -PrefixLength 24 -DefaultGateway "192.168.10.1"
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "192.168.10.10"
# Rollen und Features für ADCS und IIS installieren
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
URL=https://pki.murbal.at/pki/cps.txt
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