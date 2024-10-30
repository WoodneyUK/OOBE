##  Script runs in full Windows 11

## If a reboot is needed to be generated by the script, this script must exit before the reboot, so shell out to reboot, then exit with 1
#Start-Process -FilePath "cmd.exe" -ArgumentList '/c "timeout /t 3 /nobreak && shutdown -r -f -t 0"' -WindowStyle Hidden
#exit 1



write-host "TRunning the Audit Mode script..."
& "c:\windows\setup\scripts\LLCleanup.ps1"







# Finalize the device and return to OOBE
#Set-ExecutionPolicy Restricted -Force
rename-item -path c:\windows\panther\unattend\unattend.xml -newname unattend.old
start-sleep -Seconds 10 #Timing test
rename-item -path c:\windows\panther\unattend\oobe.xml -newname unattend.xml
start-sleep -Seconds 10 #Timing test
write-host "Verifying regional settings from Unattend"
$unfile = [xml](Get-Content "c:\windows\panther\unattend\unattend.xml")
foreach($setting in $unfile.Unattend.Settings) 
    {
    foreach ($component in $setting.Component) {
        if ((($setting.'Pass' -eq 'oobeSystem') -or ($setting.'Pass' -eq 'specialize')) -and ($component.'Name' -eq 'Microsoft-Windows-International-Core')) {
            "[$($component.InputLocale)] in [$($setting.'Pass')]"
            "[$($component.SystemLocale)] in [$($setting.'Pass')]"
            "[$($component.UILanguage)] in [$($setting.'Pass')]"
            "[$($component.UserLocale)] in [$($setting.'Pass')]"
        }
    }
}
write-host "Starting Sysprep with Reboot"
start-process -filepath "c:\windows\system32\sysprep\sysprep.exe" -argumentlist "/quiet /reboot /oobe /unattend:c:\windows\panther\unattend\unattend.xml" -wait

#with reboot
exit 1
