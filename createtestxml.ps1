[CmdletBinding()]
    param (
        [String]$userlocale = "en-US"
    )

$SysLocale = "en-US"

write-host "UserLocale:$($userlocale)"
Write-host "SystemLocale:$($SysLocale)"

$XMLPath = "c:\windows\panther\unattend\unattend.xml"

$UnattendXml = [xml] @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <SkipMachineOOBE>true</SkipMachineOOBE>
                <ProtectYourPC>3</ProtectYourPC>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideEULAPage>true</HideEULAPage>
            </OOBE>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:c:/win11-unattend/sources/install.wim#Windows 11 Enterprise" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
'@


$result = New-Item c:\windows\panther\unattend -ItemType Directory -Force


foreach ($setting in $unattendXml.Unattend.Settings) {
    #Write-host "Checking Setting:$($setting) in Unattend"
    foreach ($component in $setting.Component) {
        #write-host "Checking component:$($component) in Unattend"
        if (($setting.'Pass' -eq 'oobeSystem') -and ($component.'Name' -eq 'Microsoft-Windows-International-Core')) {
            #Write-Host "Updating Locale settings"
            $component.InputLocale = $userlocale
            $component.SystemLocale = $SysLocale
            $component.UILanguage = $userlocale
            $component.UserLocale = $userlocale
        }
    } #end foreach setting.Component
} #end foreach unattendXml.Unattend.Settings

$unattendXml.Save($XMLPath)
