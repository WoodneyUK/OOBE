## To update the Boot WIM
## edit-osdcloudwinpe -StartURL https://raw.githubusercontent.com/WoodneyUK/OOBE/main/LL-Startup.ps1
## update-osdcloudusb

##  Script runs in WINPE


## Run from URL
Write-Host "Running from Github"
Write-host "LL startup v1.9.1"
start-sleep 5


## Basic Menu
Clear-Host
Write-Host "1 - Install Windows 11"
Write-Host "2 - Gather Intune Hardware Hash"
Write-Host "Q - quit and restart"
$selection = Read-Host "Enter selection [1,2,Q]"

If ($selection -eq 'q') {
    Write-Host "restarting"
    start-sleep 5
    restart-computer -force
}ElseIf ($selection -eq  '2') {
    Write-Host "Not yet implemented, sorry.  Now restarting"
    pause
    restart-computer -force
}
Write-Host "Continuing to Install Windows..."

$Global:ScriptRootURL = "https://raw.githubusercontent.com/WoodneyUK/OOBE/main/"

## Approved Device Checks
$lenovolookup = Invoke-RestMethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/LenLookup.csv | ConvertFrom-Csv
$ComputerWMI = Get-CimInstance -ClassName Win32_ComputerSystem
$model= $ComputerWMI | select model -ExpandProperty Model
$manufacturer = $computerWMI | select manufacturer -expandproperty manufacturer

If (($manufacturer -eq "Lenovo") -and ($lenovolookup.partnumber -notcontains $model)) { 
    Write-Warning "This Lenovo Device is Not Approved, please contact EUDM with the part number : [$($model)]"
    Write-Warning "Exiting Script in 5 mins"
    start-sleep 300
    exit
    }
Else { write-host "Supported Device check complete" }

If ($manufacturer -eq "Lenovo"){
    Write-Host "Checking Lenovo BIOS Settings..."
    $quiet = new-item X:\Temp -itemtype Directory -force
    $BIOSScript = Invoke-RestMethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/Lenovo_BIOS_Settings.ps1 | out-file "X:\Temp\Lenovo_BIOS_Settings.ps1" -force -encoding ascii
    & X:\temp\Lenovo_BIOS_Settings.ps1
    }

## Lenovo Keyboard layout
Write-Host "looking up keyboard layout"
$Partnum = ((gwmi win32_computersystem).model)
$desiredkb = $lenovolookup | Where-Object {$Partnum -eq $_.PartNumber} | Select-Object Keyboard -ExpandProperty Keyboard
if ($desiredkb -eq $null -and $manufacturer -eq "Lenovo") { 
    Write-Host "Partnumber not found in lookup table, setting keyboard to en-GB"
    Write-Host "Please request EUDM team to add the part number/keyboard mapping PN:[$($Partnum)]"
    pause
    $desiredkb = "en-GB" 
    }
ElseIf ($desiredkb -eq $null -and $manufacturer -ne "Lenovo") { 
    Write-Host "Partnumber not found in lookup table, setting keyboard to en-GB"
    $desiredkb = "en-GB" 
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

#$OSName = 'Windows 11 23H2 x64'
#$OSEdition = 'Enterprise'
#$OSActivation = 'Volume'
#$OSImageIndex = 3
#$OSLanguage = $desiredkb
#$Imagefileitem = "D:\osdcloud\os\install.wim"

#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
    Restart = [bool]$False
    RecoveryPartition = [bool]$true
    OEMActivation = [bool]$True
    WindowsUpdate = [bool]$false
    WindowsUpdateDrivers = [bool]$false
    WindowsDefenderUpdate = [bool]$false
    SetTimeZone = [bool]$true
    ClearDiskConfirm = [bool]$False
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$false
    CheckSHA1 = [bool]$false
    OSImageIndex = [int32]3
    ImageFileFullName = [string]"D:\osdcloud\os\install.wim"
    ImageFileItem = @{fullname = "D:\osdcloud\os\install.wim"}
    ImageFileName = [string]"install.wim"
    ZTI = $true
}

#Launch OSDCloud
#Write-Host "Starting OSDCloud" -ForegroundColor Green
#write-host "Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage"

#Start-OSDCloud -OSName $OSName -OSEdition $OSEdition -OSActivation $OSActivation -OSLanguage $OSLanguage

invoke-osdcloud

#Start-OSDCloud -OSName "Windows 11 23H2 x64" -OSLanguage en-US -OSEdition Enterprise -OSActivation Volume

#Use this with an ISO file - Commented out 21/08/24
#Start-OSDCloud -ImagefileURL $isofilelocation -ZTI -OSImageIndex 6

#Use this with an .esd file - SJW latest
#Start-OSDCloud -findimagefile -ZTI


write-host "Windows Restore complete"
start-sleep 5

# Install Feature On Demand Fonts
Write-Host "Installing Feature on Demand Fonts..."
new-item c:\OSDCloud\temp -itemtype directory -force
#copy d:\OSDCloud\OS\FoDCoreFonts\*.* c:\OSDCloud\temp

dism /image:c:\ /scratchdir:c:\OSDCloud\temp /add-package /packagepath="d:\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Arab-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\OSDCloud\temp /add-package /packagepath="d:\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Hans-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\OSDCloud\temp /add-package /packagepath="d:\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Hant-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\OSDCloud\temp /add-package /packagepath="d:\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Jpan-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\OSDCloud\temp /add-package /packagepath="d:\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Kore-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\OSDCloud\temp /add-package /packagepath="d:\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Thai-Package~31bf3856ad364e35~amd64~~.cab"


# Load the offline registry hive from the OS volume
Write-Host "writing to offline registry"
$HivePath = "c:\Windows\System32\config\SOFTWARE"
reg load "HKLM\NewOS" $HivePath 
Start-Sleep -Seconds 5

# Set ScriptRootURL
$RegistryKey = "HKLM:\NewOS\Linklaters" 
$Result = New-Item -Path $RegistryKey -ItemType Directory -Force
$Result.Handle.Close()
$RegistryValue = "LLScriptRootURL"
$RegistryValueType = "String"
$RegistryValueData = $ScriptRootURL
$Result = New-ItemProperty -Path $RegistryKey -Name $RegistryValue -PropertyType $RegistryValueType -Value $RegistryValueData -Force

# Set OOBE wallpaper
#md c:\windows\system32\oobe\info\backgrounds
#copy-item -path "D:\OSDCloud\backgrounddefault.jpg" -destination "c:\windows\system32\oobe\info\backgrounds\backgrounddefault.jpg"
#$RegistryKey = "HKLM:\NewOS\Microsoft\Windows\CurrentVersion\Authentication\LogonUI\Background"
#$RegistryValue = "OEMBackground"
#$RegistryValueType = "Dword"
#$RegistryValueData = 1
#$Result = New-ItemProperty -Path $RegistryKey -Name $RegistryValue -Value $RegistryValueData -Force -PropertyType $RegistryValueType

# Cleanup (to prevent access denied issue unloading the registry hive)
Remove-Variable Result
Get-Variable Registry* | Remove-Variable
Start-Sleep -Seconds 5

# Unload the registry hive
Set-Location X:\
reg unload "HKLM\NewOS"

$OOBEDeployJson = @'
{
    "AddNetFX3":  {
                      "IsPresent":  false
                  },
    "RemoveAppx":  [
                    "MicrosoftTeams",
                    "Microsoft.BingWeather",
                    "Microsoft.BingNews",
                    "Microsoft.GamingApp",
                    "Microsoft.GetHelp",
                    "Microsoft.Getstarted",
                    "Microsoft.Messaging",
                    "Microsoft.MicrosoftOfficeHub",
                    "Microsoft.MicrosoftSolitaireCollection",
                    "Microsoft.MicrosoftStickyNotes",
                    "Microsoft.MSPaint",
                    "Microsoft.People",
                    "Microsoft.PowerAutomateDesktop",
                    "Microsoft.StorePurchaseApp",
                    "Microsoft.Todos",
                    "microsoft.windowscommunicationsapps",
                    "Microsoft.WindowsFeedbackHub",
                    "Microsoft.WindowsMaps",
                    "Microsoft.WindowsSoundRecorder",
                    "Microsoft.Xbox.TCUI",
                    "Microsoft.XboxGameOverlay",
                    "Microsoft.XboxGamingOverlay",
                    "Microsoft.XboxIdentityProvider",
                    "Microsoft.XboxSpeechToTextOverlay",
                    "Microsoft.YourPhone",
                    "Microsoft.ZuneMusic",
                    "Microsoft.ZuneVideo"
                   ],
    "UpdateDrivers":  {
                          "IsPresent":  false
                      },
    "UpdateWindows":  {
                          "IsPresent":  true
                      }
}
'@
#If (!(Test-Path "C:\ProgramData\OSDeploy")) {
#    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
#}
#$OOBEDeployJson | Out-File -FilePath "C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json" -Encoding ascii -Force


# Create an Undo disk
#Write-Host "Create Undo now"
#pause


# Download custom file(s)
#New-Item c:\Windows\system32\Linklaters\OOBE -force -ItemType Directory
#copy-item -path "X:\OSDCloud\Config\OOBEDeploy\OOBEDeploy.ps1" -destination "c:\Windows\system32\Linklaters\OOBE\OOBEDeploy.ps1"
#Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/OOBEDeploy.ps1 | out-file "c:\Windows\system32\Linklaters\OOBE\OOBEDeploy.ps1" -force -encoding ascii
#Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/setupcomplete.ps1 | out-file "c:\osdcloud\scripts\setupcomplete\setupcomplete.ps1" -force -encoding ascii
#Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/setupcomplete.cmd | out-file "c:\osdcloud\scripts\setupcomplete\setupcomplete.cmd" -force -encoding ascii
#Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/OOBEDeploy.ps1 | out-file "c:\windows\setup\scripts\oobe.ps1" -force -encoding ascii
#Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/oobe.cmd | out-file "c:\windows\setup\scripts\oobe.cmd" -force -encoding ascii
Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/createtestxml.ps1 | out-file "c:\windows\setup\scripts\createtestxml.ps1" -force -encoding ascii
invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/wificonnect.ps1 | out-file "c:\windows\setup\scripts\wificonnect.ps1" -force -encoding ascii

#Custom unattend.xml
New-Item c:\windows\panther\unattend -force -ItemType Directory
#copy-item -path "x:\OSDCloud\Config\OOBEDeploy\Unattend.xml" -destination "C:\Windows\panther\unattend\unattend.xml"
#Install-Module -Name WindowsImageTools -force
#New-UnattendXml -TimeZone 'GMT Standard Time' -path c:\temp\unattend.xml -InputLocale $desiredkb -SystemLocale "en-US" -UILanguage $desiredkb -UserLocale $desiredkb

#Create the custom unattend.xml
& "c:\windows\setup\scripts\createtestxml.ps1" -userlocale $desiredKB


# Add a 2 mins delay into Setupcomplete to allow drivers to install before Updates start
#$setupcompletecmd = @'
#timeout 120
#%windir%\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy ByPass -File C:\Windows\Setup\scripts\SetupComplete.ps1
#'@
#$setupcompletecmd | Out-File -FilePath "C:\Windows\Setup\Scripts\SetupComplete.cmd" -Encoding ascii -Force

#Save the wifi profile for use later
#netsh wlan export profile key=clear folder=c:\osdcloud\configs

set-setupcompletesetwifi
start-sleep 30

write-host "LL Startup script completed, waiting 10 seconds then restarting..."
start-sleep 10

Restart-Computer -Force
