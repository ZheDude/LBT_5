Install-WindowsFeature -Name NPAS -IncludeManagementTools

# Konfiguration des NPS

Mit netsh nps sollen nur Clients angelegt werden. die Definition der Policies erfolgt über die GUI
netsh
nps
# Fortigate
add client name "FortiGate" address = "192.168.0.254" sharedsecret = "SuperGeheim123!"
add crp name = "FortiGate" processingorder = 1 conditionid = "0x100c" conditiondata = "192.168.0.254"
# Cisco Switches
add client name "CoreSW1" address = "192.168.0.254" sharedsecret = "SuperGeheim123!" vendor = "Cisco"
add client name "CoreSW2" address = "192.168.0.254" sharedsecret = "SuperGeheim123!" vendor = "Cisco"
add client name "DistSW1" address = "192.168.0.254" sharedsecret = "SuperGeheim123!" vendor = "Cisco"
add client name "DistSw2" address = "192.168.0.254" sharedsecret = "SuperGeheim123!" vendor = "Cisco"


add np name = "SwitchConnections2 (LVL15)" conditionid = "0x1fb5" conditiondata = "S-1-5-21-2862227730-4028621430-2473981021-1108" profileid = "0x1388" profiledata = "shell:priv-lvl=15" profileid = "0x100f" profiledata = "TRUE" profileid = "0x1009" profiledata = "0x1" profileid = "0x6" profiledata = "0x1" processingorder = 1
add np name = "FortiGate_Radius_ad" conditionid = "0x1fb5" conditiondata = "S-1-5-21-2862227730-4028621430-2473981021-1108" conditionid = "0x100c" conditiondata = "192.168.0.254" profileid = "0x1005" profiledata = "FALSE" profileid = "0x100f" profiledata = "TRUE" profileid = "0x1009" profiledata = "0x2" profileid = "0x1009" profiledata = "0x3" profileid = "0x1009" profiledata = "0x9" profileid = "0x1009" profiledata = "0x4" profileid = "0x1009" profiledata = "0xa" profileid = "0x1a" profiledata = "0100003044010DRadius User" profileid = "0x7" profiledata = "0x1" profileid = "0x6" profiledata = "0x2" processingorder = 4