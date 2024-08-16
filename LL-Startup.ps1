## To update the Boot WIM
## edit-osdcloudwinpe -StartURL https://raw.githubusercontent.com/WoodneyUK/OOBE/main/LL-Startup.ps1

## Run from URL
Write-Host "Running from Github"
Write-host "LL startup v1.1"
start-sleep 5

## Approved Device Checks
$ApprovedDevices = Get-Content "X:\OSDCloud\Config\Scripts\Startup\approveddevices.txt"
$model=Get-CimInstance -ClassName Win32_ComputerSystem
$computermodel=$model.Model.substring(0,4)
#If (($model.Manufacturer -eq "Lenovo") -and ($approveddevices -notcontains $computermodel)) { Write-Warning "This Lenovo Device is Not Approved, please exit" }
write-host "Supported Device check complete"

start-sleep 5

## Lenovo Keyboard layout
Write-Host "looking up keyboard layout"
$lenovolookup = Invoke-RestMethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/LenLookup.csv | ConvertFrom-Csv
$desiredkb = $lenovolookup | Where-Object {((gwmi win32_computersystem).model) -eq $_.PartNumber} | Select-Object Keyboard -ExpandProperty Keyboard
if ($desiredkb -eq $null) { 
    Write-Host "Partnumber not found in lookup table, setting keyboard to en-US"
    $desiredkb = "en-US" 
    }
Else { Write-Host "Keyboard detected as $desiredkb" }


## Linklaters Office UI
#start-process "X:\OSDCloud\Config\Scripts\Startup\3.0.3.0\x64\UI++64.exe" -argumentlist "/config:X:\OSDCloud\Config\Scripts\Startup\3.0.3.0\UI++.xml" -Wait
#$LLOffice = ((get-itemproperty -Path HKLM:Software\Linklaters -Name LLOffice).LLOffice)
#Write-Host "Starting Windows Install, and adding Language Pack:$($LLOffice)"

#start-sleep 5

# Download the MS ISO if needed
#Update-OSDCloudUSB -driverpack Lenovo,wifi -OSName "Windows 11 22H2 x64" -OSLanguage "en-US" -OSLicense Volume



#Variables to define the Windows OS / Edition etc to be applied during OSDCloud
$OSName = 'Windows 11 23H2 x64'
$OSEdition = 'Pro'
$OSActivation = 'Retail'
$OSLanguage = $desiredkb

#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
    Restart = [bool]$True
    RecoveryPartition = [bool]$true
    OEMActivation = [bool]$True
    WindowsUpdate = [bool]$true
    WindowsUpdateDrivers = [bool]$false
    WindowsDefenderUpdate = [bool]$true
    SetTimeZone = [bool]$true
    ClearDiskConfirm = [bool]$False
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$true
    CheckSHA1 = [bool]$true
    OSImageIndex = 6
}

#Launch OSDCloud
Write-Host "Starting OSDCloud" -ForegroundColor Green
write-host "Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage"

#Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage

#Start-OSDCloud -OSName "Windows 11 23H2 x64" -OSLanguage en-US -OSEdition Enterprise -OSActivation Volume
Start-OSDCloud -findimagefile -ZTI
#pause

write-host "Windows Restore complete"
start-sleep 5

# Install Feature On Demand Fonts
Write-Host "Installing Feature on Demand Fonts"
md c:\temp
dism /image:c:\ /scratchdir:c:\temp /add-package /packagepath="d:\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Arab-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\temp /add-package /packagepath="d:\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Hans-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\temp /add-package /packagepath="d:\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Hant-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\temp /add-package /packagepath="d:\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Jpan-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\temp /add-package /packagepath="d:\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Kore-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\temp /add-package /packagepath="d:\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Thai-Package~31bf3856ad364e35~amd64~~.cab"

# Load the offline registry hive from the OS volume
#Write-Host "writing to offline registry"
#$HivePath = "c:\Windows\System32\config\SOFTWARE"
#reg load "HKLM\NewOS" $HivePath 
#Start-Sleep -Seconds 5

# Set LL Office Info
#$RegistryKey = "HKLM:\NewOS\Linklaters" 
#$Result = New-Item -Path $RegistryKey -ItemType Directory -Force
#$Result.Handle.Close()
#$RegistryValue = "LLOfficeLang"
#$RegistryValueType = "String"
#$RegistryValueData = $LLOffice
#$Result = New-ItemProperty -Path $RegistryKey -Name $RegistryValue -PropertyType $RegistryValueType -Value $RegistryValueData -Force

# Set OOBE wallpaper
#md c:\windows\system32\oobe\info\backgrounds
#copy-item -path "D:\OSDCloud\backgrounddefault.jpg" -destination "c:\windows\system32\oobe\info\backgrounds\backgrounddefault.jpg"
#$RegistryKey = "HKLM:\NewOS\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background"
#$RegistryValue = "OEMBackground"
#$RegistryValueType = "Dword"
#$RegistryValueData = 1
#$Result = New-ItemProperty -Path $RegistryKey -Name $RegistryValue -Value $RegistryValueData -Force -PropertyType $RegistryValueType

# Cleanup (to prevent access denied issue unloading the registry hive)
#Remove-Variable Result
#Get-Variable Registry* | Remove-Variable
#Start-Sleep -Seconds 5

# Unload the registry hive
#Set-Location X:\
#reg unload "HKLM\NewOS"

# Apply Latest CU
#Write-Host "Applying Latest Windows Updates"
#md c:\temp
#$env:temp = "c:\temp"
#set-location c:
#update-mywindowsimage -path c: -update all

# Create an Undo disk
#Write-Host "Create Undo now"
#pause


# Drop a custom unattend.xml which runs a post-install script
#New-Item c:\Windows\system32\Linklaters\OOBE -force -ItemType Directory
#copy-item -path "X:\OSDCloud\Config\OOBEDeploy\OOBEDeploy.ps1" -destination "c:\Windows\system32\Linklaters\OOBE\OOBEDeploy.ps1"
#Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/OOBEDeploy.ps1 | out-file "c:\Windows\system32\Linklaters\OOBE\OOBEDeploy.ps1" -force -encoding ascii
#Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/setupcomplete.ps1 | out-file "c:\osdcloud\scripts\setupcomplete\setupcomplete.ps1" -force -encoding ascii
#Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/setupcomplete.cmd | out-file "c:\osdcloud\scripts\setupcomplete\setupcomplete.cmd" -force -encoding ascii
#Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/OOBEDeploy.ps1 | out-file "c:\windows\setup\scripts\oobe.ps1" -force -encoding ascii
#Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/oobe.cmd | out-file "c:\windows\setup\scripts\oobe.cmd" -force -encoding ascii
Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/createtestxml.ps1 | out-file "c:\windows\setup\scripts\createtestxml.ps1" -force -encoding ascii

#Custom unattend.xml
#New-Item c:\windows\panther\unattend -force -ItemType Directory
#copy-item -path "x:\OSDCloud\Config\OOBEDeploy\Unattend.xml" -destination "C:\Windows\panther\unattend\unattend.xml"
#Install-Module -Name WindowsImageTools -force
#New-UnattendXml -TimeZone 'GMT Standard Time' -path c:\temp\unattend.xml -InputLocale "en-GB" -SystemLocale "en-US" -UILanguage "en-GB" -UserLocale "en-GB"

#Create the custom unattend.xml
& "c:\windows\setup\scripts\createtestxml.ps1"


#Write-Host "I would normally Restart Computer now, but not during development :-)"
#Write-Host "so i'll just pause and allow you develop some more or restart yourself"
#Restart-Computer -Force
#pause
