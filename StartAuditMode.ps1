write-host "This is a custom Audit Mode script"

#Write-Host "Setting Reg"
#Set-ItemProperty -Path HKLM:\SYSTEM\Setup\Status -Name AuditBoot -Value 0

start-sleep 30

# Shell out to reboot
Start-Process -FilePath "cmd.exe" -ArgumentList '/c "timeout /t 3 /nobreak && shutdown -r -f -t 0"' -WindowStyle Hidden

# set exit code 1 so that Windows knows it needs a reboot
# https://learn.microsoft.com/en-us/windows-hardware/customize/desktop/unattend/microsoft-windows-deployment-runsynchronous-runsynchronouscommand-willreboot#values
Exit 1
