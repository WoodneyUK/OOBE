## To update the Boot WIM
## edit-osdcloudwinpe -StartURL https://raw.githubusercontent.com/WoodneyUK/OOBE/main/LL-Startup.ps1

## Run from URL
Write-Host "Running from Github"
Write-host "Hi Ace, Greg"
start-sleep 5

## Approved Device Checks
$ApprovedDevices = Get-Content "X:\OSDCloud\Config\Scripts\Startup\approveddevices.txt"
$model=Get-CimInstance -ClassName Win32_ComputerSystem
$computermodel=$model.Model.substring(0,4)
If (($model.Manufacturer -eq "Lenovo") -and ($approveddevices -notcontains $computermodel)) { Write-Warning "This Lenovo Device is Not Approved, please exit" }
write-host "Supported Device check complete"

start-sleep 5

## Linklaters Office UI
start-process "X:\OSDCloud\Config\Scripts\Startup\3.0.3.0\x64\UI++64.exe" -argumentlist "/config:X:\OSDCloud\Config\Scripts\Startup\3.0.3.0\UI++.xml" -Wait
$LLOffice = ((get-itemproperty -Path HKLM:Software\Linklaters -Name LLOffice).LLOffice)
Write-Host "Starting Windows Install, and adding Language Pack:$($LLOffice)"

start-sleep 5

#Start-OSDCloud -OSName "Windows 11 23H2 x64" -OSLanguage en-US -OSEdition Enterprise -OSActivation Volume
Start-OSDCloud -findimagefile -ZTI
#pause

write-host "Windows Restore complete"
start-sleep 5

# Drop a custom unattend.xml which runs a post-install script
New-Item c:\Windows\system32\Linklaters\OOBE -force -ItemType Directory
#copy-item -path "X:\OSDCloud\Config\OOBEDeploy\OOBEDeploy.ps1" -destination "c:\Windows\system32\Linklaters\OOBE\OOBEDeploy.ps1"
#Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/OOBEDeploy.ps1 | out-file "c:\Windows\system32\Linklaters\OOBE\OOBEDeploy.ps1" -force -encoding ascii
Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/setupcomplete.ps1 | out-file "c:\osdcloud\scripts\setupcomplete\setupcomplete.ps1" -force -encoding ascii
Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/setupcomplete.cmd | out-file "c:\osdcloud\scripts\setupcomplete\setupcomplete.cmd" -force -encoding ascii
#Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/OOBEDeploy.ps1 | out-file "c:\windows\setup\scripts\oobe.ps1" -force -encoding ascii
#Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/oobe.cmd | out-file "c:\windows\setup\scripts\oobe.cmd" -force -encoding ascii

New-Item c:\windows\panther\unattend -force -ItemType Directory
copy-item -path "x:\OSDCloud\Config\OOBEDeploy\Unattend.xml" -destination "C:\Windows\panther\unattend\unattend.xml"

Write-Host "Restarting Computer..."
Restart-Computer -Force

#pause
