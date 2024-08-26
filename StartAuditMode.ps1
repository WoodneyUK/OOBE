write-host "This is a custom Audit Mode script"

Write-Host "Setting Reg"
#Set-ItemProperty -Path HKLM:\SYSTEM\Setup\Status -Name AuditBoot -Value 0

start-sleep 30

Write-Host "restarting"
restart-computer -force
