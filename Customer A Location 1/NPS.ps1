Rename-Computer -NewName "HQ-NPS" -Force -Restart

$IP = "192.168.0.15"
$SubnetMask = "255.255.255.0"
$Gateway = "192.168.0.254"
$InterfaceAlias = (Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }).InterfaceAlias

New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $IP -PrefixLength 24 -DefaultGateway $Gateway
Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias -ServerAddresses ("192.168.0.10")


Install-WindowsFeature -Name NPAS -IncludeManagementTools

# AD Join
$DomainName = "corp.murbal.at"
$DomainCreds = Get-Credential -Message "Bitte die Anmeldeinformationen eines Domänenadministrators eingeben"
Add-Computer -DomainName $DomainName -Credential $DomainCreds -Restart

# Konfiguration des NPS
Mit netsh nps sollen nur Clients angelegt werden. die Definition der Policies erfolgt über die GUI
netsh
nps
# Fortigate
add client name = "FortiGate" address = "192.168.0.254" sharedsecret = "SuperGeheim123!"
add crp name = "FortiGate" processingorder = 1 conditionid = "0x100c" conditiondata = "192.168.0.254"
# Cisco Switches
add client name = "CoreSW1" address = "192.168.0.1" sharedsecret = "SuperGeheim123!" vendor = "Cisco"
add client name = "CoreSW2" address = "192.168.0.2" sharedsecret = "SuperGeheim123!" vendor = "Cisco"
add client name = "DistSW1" address = "192.168.0.3" sharedsecret = "SuperGeheim123!" vendor = "Cisco"
add client name = "DistSw2" address = "192.168.0.4" sharedsecret = "SuperGeheim123!" vendor = "Cisco"


add np name = "SwitchConnections2 (LVL15)" conditionid = "0x1fb5" conditiondata = "S-1-5-21-2862227730-4028621430-2473981021-1108" profileid = "0x1388" profiledata = "shell:priv-lvl=15" profileid = "0x100f" profiledata = "TRUE" profileid = "0x1009" profiledata = "0x1" profileid = "0x6" profiledata = "0x1" processingorder = 1
add np name = "FortiGate_Radius_ad" conditionid = "0x1fb5" conditiondata = "S-1-5-21-2862227730-4028621430-2473981021-1108" conditionid = "0x100c" conditiondata = "192.168.0.254" profileid = "0x1005" profiledata = "FALSE" profileid = "0x100f" profiledata = "TRUE" profileid = "0x1009" profiledata = "0x2" profileid = "0x1009" profiledata = "0x3" profileid = "0x1009" profiledata = "0x9" profileid = "0x1009" profiledata = "0x4" profileid = "0x1009" profiledata = "0xa" profileid = "0x1a" profiledata = "0100003044010DRadius User" profileid = "0x7" profiledata = "0x1" profileid = "0x6" profiledata = "0x2" processingorder = 4