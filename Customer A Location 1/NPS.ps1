Install-WindowsFeature -Name NPAS -IncludeManagementTools

# Konfiguration des NPS

Mit netsh nps sollen nur Clients angelegt werden. die Definition der Policies erfolgt über die GUI
netsh
nps
add client name "FortiGate" address = "192.168.0.254" sharedsecret = "SuperGeheim123!" vendor = "Cisco"
