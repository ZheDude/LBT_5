Install-WindowsFeature -Name Web-Server, Web-WebServer, Web-Common-Http, Web-Default-Doc, Web-Static-Content, Web-Dir-Browsing, Web-Http-Errors -IncludeManagementTools


$folderPath = "C:\CertEnroll"
$shareName = "CertEnroll"
$domainGroup = "CORP\Cert Publishers"

if (!(Test-Path $folderPath)) {
    New-Item -Path $folderPath -ItemType Directory
    Write-Host "Folder 'CertEnroll' created at C:\."
} else {
    Write-Host "Folder 'CertEnroll' already exists."
}

Get-SmbShare -Name $shareName

$acl = Get-Acl -Path $folderPath
$accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($domainGroup, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($accessRule)

Set-Acl -Path $folderPath -AclObject $acl

# IIS Konfiguration
# -----------------

