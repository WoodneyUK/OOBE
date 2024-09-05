## To update the Boot WIM
## edit-osdcloudwinpe -StartURL https://st2uupbw11seuwq01.blob.core.windows.net/oobe/ll-startup.ps1
## update-osdcloudusb

##  Script runs in WINPE

[decimal]$minimumusb = 1.0

## Run from URL
Write-host "LL startup v1.9.2"
Write-Host "Running from [$($Global:ScriptRootURL)]"
start-sleep 5

## USB version check
#Use a decimal var so that it will be 0 if version.txt does not exist
[decimal]$usbver = get-content "D:\OSDCloud\MediaVersion.txt" -ErrorAction SilentlyContinue
If ($usbver -lt $minimumusb){
    Write-Warning "USB version [$($usbver)] is lower than required version [$($minimumusb)], please rebuild this using latest USB iso"
    Write-Warning "Latest ISO is available : [\\acopfs05\sccm$\OSD\LL_W11_BootUSB]"
    Write-Warning "Cannot continue, restarting"
    pause
    }
Else{ Write-Host "USB version check completed" }


## Basic Menu
Clear-Host
Write-Host "1 - Install Windows 11"
Write-Host "2 - Gather Intune Hardware Hash"
Write-Host "Q - quit and restart"
$selection = Read-Host "Enter selection [1,2,Q]"

If ($selection -eq 'q') {
    Write-Host "restarting"
    start-sleep 5
    wpeutil reboot
}ElseIf ($selection -eq  '2') {
    # Call the get-windowsautopiliotinfo script
    Invoke-RestMethod https://st2uupbw11seuwq01.blob.core.windows.net/oobe/hh/gethh.ps1 | out-file $env:temp\gethh1.ps1 -force -encoding ascii
    & $env:temp\gethh1.ps1
    #Write-Host "Not yet implemented, sorry.  Now restarting"
    pause
    wpeutil reboot
}
Write-Host "Continuing to Install Windows..."


## Approved Device Checks
$lenovolookup = Invoke-RestMethod -uri "https://raw.githubusercontent.com/WoodneyUK/OOBE/main/LenLookup.csv" | ConvertFrom-Csv
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
    $BIOSScript = Invoke-RestMethod -uri "$($Global:ScriptRootURL)/lenovo_bios_settings.ps1" | out-file "X:\Temp\Lenovo_BIOS_Settings.ps1" -force -encoding ascii
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


#Set OSDCloud Vars
$Global:MyOSDCloud = [ordered]@{
    Restart = [bool]$False
    RecoveryPartition = [bool]$true
    OEMActivation = [bool]$True
    WindowsUpdate = [bool]$false
    WindowsUpdateDrivers = [bool]$false
    WindowsDefenderUpdate = [bool]$true
    ApplyCatalogFirmware = $true
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


invoke-osdcloud


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


# Cleanup (to prevent access denied issue unloading the registry hive)
Remove-Variable Result
Get-Variable Registry* | Remove-Variable
Start-Sleep -Seconds 5

# Unload the registry hive
Set-Location X:\
reg unload "HKLM\NewOS"


# Download custom file(s)
Invoke-restmethod -uri "$($Global:ScriptRootURL)/createxml.ps1" | out-file "c:\windows\setup\scripts\createxml.ps1" -force -encoding ascii
invoke-restmethod -uri "$($Global:ScriptRootURL)/wificonnect.ps1" | out-file "c:\windows\setup\scripts\wificonnect.ps1" -force -encoding ascii

#Custom unattend.xml
New-Item c:\windows\panther\unattend -force -ItemType Directory

#Create the custom unattend.xml
& "c:\windows\setup\scripts\createxml.ps1" -userlocale $desiredKB

#Save the wifi profile for use later
netsh wlan export profile key=clear folder=c:\osdcloud\configs

write-host "LL Startup script completed, waiting 10 seconds then restarting..."
start-sleep 10


wpeutil reboot
