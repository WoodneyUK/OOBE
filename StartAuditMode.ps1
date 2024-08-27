write-host "This is a custom Audit Mode script"

#Write-Host "Setting Reg"
#Set-ItemProperty -Path HKLM:\SYSTEM\Setup\Status -Name AuditBoot -Value 0

#start-sleep 30

#Download and execute the cleanup script
Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/CleanUp.ps1 | out-file "c:\windows\setup\scripts\Cleanup.ps1" -force -encoding ascii
& "c:\windows\setup\scripts\Cleanup.ps1"

# with reboot
# Shell out to reboot
#Start-Process -FilePath "cmd.exe" -ArgumentList '/c "timeout /t 3 /nobreak && shutdown -r -f -t 0"' -WindowStyle Hidden

rename-item -path c:\windows\panther\unattend\unattend.xml -newname unattend.old
rename-item -path c:\windows\panther\unattend\oobe.xml -newname unattend.xml

start-process -filepath "c:\windows\system32\sysprep\sysprep.exe" -argumentlist "/quiet /reboot /oobe /unattend:c:\windows\panther\unattend\unattend.xml" -wait



#without reboot
#exit 0

#with reboot
exit 1
