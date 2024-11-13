## To update the Boot WIM
## edit-osdcloudwinpe -StartURL https://st2uupbw11seuwq01.blob.core.windows.net/oobe/ll-startup.ps1
## update-osdcloudusb

##  Script runs in WINPE

[decimal]$minimumusb = 1.0
$DateFormat = 'dd-MM-yyyy HH:mm:ss'
$OSDCloud_StartTimeUTC = $(Get-Date ([System.DateTime]::UtcNow) -Format $DateFormat)
## Run from URL
Write-host "LL startup v1.9.2"
Write-Host "Running from [$($Global:ScriptRootURL)]"
start-sleep 5

$USBBootVol = get-volume | where-object {$_.filesystemlabel -match 'WINPE'}
#$USBDataVol = get-volume | where-object {$_.filesystemlabel -match 'OSDCloud' -and $_.DriveType -eq 'Removable'}
$USBDataVol = get-volume | where-object {$_.filesystemlabel -match 'OSDCloud'}

#If (!$USBDataVol) {
#	#Its probably running from an .iso file, so grab the datavol
# 	$USBDataVol = get-volume | where-object {$_.filesystemlabel -match 'OSDCloud' -and $_.DriveType -eq 'CD-ROM'} | select -first 1
#}

## USB version check
#Use a decimal var so that it will be 0 if version.txt does not exist
[decimal]$usbver = get-content "$($USBDataVol.driveletter):\OSDCloud\mediaversion.txt" -ErrorAction SilentlyContinue
If ($usbver -lt $minimumusb){
    Write-Warning "USB version [$($usbver)] is lower than required version [$($minimumusb)], please rebuild this using latest USB iso"
    Write-Warning "Latest ISO is available : [\\acopfs05\sccm$\OSD\LL_W11_BootUSB]"
    $verinput = read-host -Prompt "Computer will now shutdown, unless you type CONTINUE"

	If ($verinput -ne "CONTINUE"){ 
 		    Write-host "now shutting down..."
       	    wpeutil shutdown 
   	    }
        Else {
     	    Write-Host "This is for testing only." -ForegroundColor Yellow -Backgroundcolor DarkGray
            pause
	    }
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
    #Invoke-RestMethod https://st2uupbw11seuwq01.blob.core.windows.net/oobe/hh/gethh.ps1 | out-file $env:temp\gethh1.ps1 -force -encoding ascii
    Invoke-RestMethod "$($Global:ScriptRootURL)/hh/gethh.ps1" | out-file $env:temp\gethh1.ps1 -force -encoding ascii
    & $env:temp\gethh1.ps1
    Write-Host "Device will now shutdown"
    pause
    wpeutil shutdown
}
Write-Host "Continuing to Install Windows..."

## Country 
Clear-Host
Write-Host "Select Country"
Write-Host "1 - Belgium"
Write-Host "2 - Brazil"
Write-Host "3 - China"
Write-Host "4 - France"
Write-Host "5 - Germany"
Write-Host "6 - Hong Kong"
Write-Host "7 - Indonesia"
Write-Host "8 - Italy"
Write-Host "9 - Japan"
Write-Host "10 - Korea"
Write-Host "11 - Luxembourg"
Write-Host "12 - Netherlands"
Write-Host "13 - Poland"
Write-Host "14 - Portugal"
Write-Host "15 - Russia"
Write-Host "16 - Singapore"
Write-Host "17 - Spain"
Write-Host "18 - Sweden"
Write-Host "19 - United Arab Emirates"
Write-Host "20 - Thailand"
Write-Host "21 - United Kingdom"
Write-Host "22 - United States"
Write-Host "Q - quit and restart"
while(($CountrySelection -ne 'q') -and ($CountrySelection -notin 1..22))
    {
    $CountrySelection = Read-Host "Enter selection [1..22,q]"
    }
If ($selection -eq 'q') 
    {
    Write-Host "restarting"
    start-sleep 5
    wpeutil reboot
    }
else
    {
    switch($CountrySelection) 
        {
        1     {$Country = "Belgium";$Rootkeeby = '0813:00000813';$TimeyWimey = 'Romance Standard Time';$GeoID = '21'} # 21 - Kingdom of Belgium 
        2     {$Country = "Brazil";$Rootkeeby = '0416:00000416';$TimeyWimey = 'E. South America Standard Time';$GeoID = '32'} # 32 - Federative Republic of Brazil
        3     {$Country = "China";$Rootkeeby = '0804:{81D4E9C9-1D3B-41BC-9E6C-4B40BF79E35E}{FA550B04-5AD7-411F-A5AC-CA038EC515D7}';$TimeyWimey = 'China Standard Time';$GeoID = '45'} # 45 - People's Republic of China 
        4     {$Country = "France";$Rootkeeby = '040C:0000040C';$TimeyWimey = 'Romance Standard Time';$GeoID = '84'} # 84 - French Republic 
        5     {$Country = "Germany";$Rootkeeby = '0407:00000407';$TimeyWimey = 'W. Europe Standard Time';$GeoID = '94'} # 94 - Federal Republic of Germany
        6     {$Country = "Hong Kong";$Rootkeeby = '3C09:00000409';$TimeyWimey = 'China Standard Time';$GeoID = '104'} # 104 - Hong Kong Special Administrative Region
        7     {$Country = "Indonesia";$Rootkeeby = '0421:00000409';$TimeyWimey = 'SE Asia Standard Time';$CCulture = 'id-ID';$GeoID = '111'} # 111 - Republic of Indonesia
        8     {$Country = "Italy";$Rootkeeby = '0410:00000410';$TimeyWimey = 'W. Europe Standard Time';$GeoID = '118'} # 118 - Italian Republic
        9     {$Country = "Japan";$Rootkeeby = '0411:{03B5835F-F03C-411B-9CE2-AA23E1171E36}{A76C93D9-5523-4E90-AAFA-4DB112F9AC76}';$TimeyWimey = 'Tokyo Standard Time';$GeoID = '122'} # 122 - Japan
        10    {$Country = "Korea";$Rootkeeby = '0412:{A028AE76-01B1-46C2-99C4-ACD9858AE02F}{B5FE1F02-D5F2-4445-9C03-C568F23C99A1}';$TimeyWimey = 'Korea Standard Time';$GeoID = '134'} # 134 - Republic of Korea
        11    {$Country = "Luxembourg";$Rootkeeby = '046E:0000046E';$TimeyWimey = 'W. Europe Standard Time';$GeoID = '147'} # 147 - Grand Duchy of Luxembourg
        12    {$Country = "Netherlands";$Rootkeeby = '0413:00020409';$TimeyWimey = 'W. Europe Standard Time';$GeoID = '176'} # 176 - Kingdom of the Netherlands
        13    {$Country = "Poland";$Rootkeeby = '0415:00000415';$TimeyWimey = 'Central European Standard Time';$GeoID = '191'} # 191 - Republic of Poland
        14    {$Country = "Portugal";$Rootkeeby = '0816:00000816';$TimeyWimey = 'GMT Standard Time';$GeoID = '193'} # 193 - Portuguese Republic
        15    {$Country = "Russia";$Rootkeeby = '0419:00000419';$TimeyWimey = 'Russian Standard Time';$GeoID = '203'} # 203 - Russian Federation
        16    {$Country = "Singapore";$Rootkeeby = '0409:00000409';$TimeyWimey = 'Singapore Standard Time';$CCulture = 'en-SG';$GeoID = '215'} # 215 - Republic of Singapore
        17    {$Country = "Spain";$Rootkeeby = '0C0A:0000040A';$TimeyWimey = 'Romance Standard Time';$GeoID = '217'} # 217 - Kingdom of Spain
        18    {$Country = "Sweden";$Rootkeeby = '041D:0000041D';$TimeyWimey = 'W. Europe Standard Time';$GeoID = '221'} # 221 - Kingdom of Sweden
        19    {$Country = "UAE";$Rootkeeby = '0409:00000409';$TimeyWimey = 'Arabian Standard Time';$CCulture = 'ar-AE';$GeoID = '224'} # 224 - United Arab Emirates
        20    {$Country = "Thailand";$Rootkeeby = '0409:00000409';$TimeyWimey = 'SE Asia Standard Time';$GeoID = '227'} # 227 - Kingdom of Thailand
        21    {$Country = "UK";$Rootkeeby = '0809:00000809';$TimeyWimey = 'GMT Standard Time';$GeoID = '242'} # 242 - United Kingdom
        22    {$Country = "US";$Rootkeeby = '0409:00000409';$TimeyWimey = 'Eastern Standard Time';$GeoID = '244'} # 244 - United States
        }
    }
    
## Approved Device Checks
#$lenovolookup = Invoke-RestMethod -uri "https://raw.githubusercontent.com/WoodneyUK/OOBE/main/LenLookup.csv" | ConvertFrom-Csv
$lenovolookup = Invoke-RestMethod -uri "https://st2uupbw11seuwq01.blob.core.windows.net/oobe/lenlookup.csv" | ConvertFrom-Csv
$ComputerWMI = Get-CimInstance -ClassName Win32_ComputerSystem
$model= $ComputerWMI | select model -ExpandProperty Model
$manufacturer = $computerWMI | select manufacturer -expandproperty manufacturer

If (($manufacturer -eq "Lenovo") -and ($lenovolookup.partnumber -notcontains $model)) { 
    Write-Warning "This Lenovo Device is Not Approved, please contact EUDM with the part number : [$($model)]"
    Write-Warning "Device will now shutdown"
    pause
    wpeutil shutdown
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
    SetTimeZone = [bool]$true
    ClearDiskConfirm = [bool]$False
    ShutdownSetupComplete = [bool]$false
    SyncMSUpCatDriverUSB = [bool]$false
    ApplyCatalogFirmware = [bool]$true
    ApplyCatalogDrivers = [bool]$false
    CheckSHA1 = [bool]$false
    OSImageIndex = [int32]3
    ImageFileFullName = [string]"$($USBDataVol.driveletter):\OSDCloud\os\install.wim"
    ImageFileItem = @{fullname = "$($USBDataVol.driveletter):\OSDCloud\os\install.wim"}
    ImageFileName = [string]"install.wim"
    ZTI = [bool]$true
}


invoke-osdcloud


write-host "Windows Restore complete"
start-sleep 5

# Install Feature On Demand Fonts
Write-Host "Installing Feature on Demand Fonts..."
new-item c:\OSDCloud\temp -itemtype directory -force
#copy $($USBDataVol.driveletter):\OSDCloud\OS\FoDCoreFonts\*.* c:\OSDCloud\temp

dism /image:c:\ /scratchdir:c:\OSDCloud\temp /add-package /packagepath="$($USBDataVol.driveletter):\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Arab-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\OSDCloud\temp /add-package /packagepath="$($USBDataVol.driveletter):\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Hans-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\OSDCloud\temp /add-package /packagepath="$($USBDataVol.driveletter):\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Hant-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\OSDCloud\temp /add-package /packagepath="$($USBDataVol.driveletter):\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Jpan-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\OSDCloud\temp /add-package /packagepath="$($USBDataVol.driveletter):\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Kore-Package~31bf3856ad364e35~amd64~~.cab"
dism /image:c:\ /scratchdir:c:\OSDCloud\temp /add-package /packagepath="$($USBDataVol.driveletter):\OSDCloud\OS\FoDCoreFonts\Microsoft-Windows-LanguageFeatures-Fonts-Thai-Package~31bf3856ad364e35~amd64~~.cab"

# Set Country for MPO to configure

$ConfigFilesDir = 'C:\Windows\System32\Linklaters\Engineering\UsersRegionAndCulture'
$ConfigFile = 'Country.config'
New-Item $ConfigFilesDir -ItemType Directory -Force
Set-Content $ConfigFilesDir\$ConfigFile -Value $Country -Force

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

#Create registry build hive
$BuildRegistryKey = "$RegistryKey\Engineering\Build"
$null = New-Item -Path $BuildRegistryKey -ItemType Directory -Force
#Set OSDCloud USB version
$null = New-ItemProperty -Path $BuildRegistryKey -Name 'OSDCloud_Version' -PropertyType String -Value $usbver -Force
$null = New-ItemProperty -Path $BuildRegistryKey -Name 'OSDCloud_RootKB' -PropertyType String -Value $Rootkeeby -Force
#Set OSDCLoud start time
$null = New-ItemProperty -Path $BuildRegistryKey -Name 'OSDCloud_StartTimeUTC' -PropertyType String -Value $OSDCloud_StartTimeUTC -Force
#Set FoD requied keys for BuildState detection (temporary until FoD phase removed from BuildState)
$FoDs = @('Language.Fonts.Arab~~~und-ARAB~0.0.1.0',
        'Language.Fonts.Hans~~~und-HANS~0.0.1.0',
        'Language.Fonts.Hant~~~und-HANT~0.0.1.0',
        'Language.Fonts.Jpan~~~und-JPAN~0.0.1.0',
        'Language.Fonts.Kore~~~und-KORE~0.0.1.0',
        'Language.Fonts.Thai~~~und-THAI~0.0.1.0' )

foreach($food in $FoDs)
    {
    $FoDPath = "$($BuildRegistryKey)\FoD\$($food)"
    $null = New-Item -Path $FoDPath -ItemType Directory -Force
    $null = New-ItemProperty -Path $FoDPath -Name State -PropertyType String -Value 'Installed' -Force
    }
    
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
Invoke-restmethod -uri "$($Global:ScriptRootURL)/cleanup.ps1" | out-file "c:\windows\setup\scripts\LLCleanup.ps1" -force -encoding ascii
Invoke-restmethod -uri "$($Global:ScriptRootURL)/startauditmode.ps1" | out-file "c:\windows\setup\scripts\startauditmode.ps1" -force -encoding ascii

#Custom unattend.xml
New-Item c:\windows\panther\unattend -force -ItemType Directory

#Create the custom unattend.xml
& "c:\windows\setup\scripts\createxml.ps1" -userlocale $desiredKB -TimeZone $TimeyWimey -GeoID $GeoID -RKB $Rootkeeby

#Save the wifi profile for use later
netsh wlan export profile key=clear folder=c:\osdcloud\configs

cls

write-host "LL Startup script completed"

write-host  -foregroundcolor Green "****************************************************"
write-host  -foregroundcolor Green "               Rebooting in 10 seconds"
write-host  -foregroundcolor Green "  You can safely remove the USB after this reboot"
Write-host  -foregroundcolor Green "****************************************************"
start-sleep 10


wpeutil reboot
