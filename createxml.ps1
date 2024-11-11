##  Script runs in WINPE

[CmdletBinding()]
    param (
        [String]$userlocale = "en-US",
        [String]$TimeZone = 'Eastern Standard Time',
        [String]$GeoID = '244'
    )

$SysLocale = "en-US"

write-host "UserLocale:$($userlocale)"
Write-host "SystemLocale:$($SysLocale)"
Write-host "TimeZone:$($TimeZone)"
Write-host "GeoID:$($GeoID)"

$auditmodescript = "$($Global:ScriptRootURL)/StartAuditMode.ps1"
$AuditModeXMLPath = "c:\windows\panther\unattend\unattend.xml" # used during the setup as part of OSDCloud
$SysprepXMLPath = "c:\windows\panther\unattend\oobe.xml" # used during Audit mode to finalise the settings
$RecoveryXMLPath = "c:\recovery\autoapply\unattend.xml" # used for FreshStart recovery (TBC)
$IntlCPLXMLPath = "c:\Windows\System32\Linklaters\Engineering\Lang\$userlocale.xml" # used fduring Buildstate to apply Region formatting and other options (TBC)

$result = New-Item c:\windows\panther\unattend -ItemType Directory -Force
$result = New-Item c:\recovery\autoapply -ItemType Directory -Force
$result = New-Item c:\Windows\System32\Linklaters\Engineering\Lang -ItemType Directory -Force

$AuditModeXml = [xml] @"
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Reseal>
                <Mode>Audit</Mode>
            </Reseal>
        </component>
    </settings>
    <settings pass="auditUser">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Description>LL:Start Wifi</Description>
                    <Path>PowerShell -executionpolicy bypass -Command "c:\windows\setup\scripts\wificonnect.ps1"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <Description>LL:Installing Windows Updates - Run 1</Description>
                    <Path>PowerShell -executionpolicy bypass -Command "start-windowsupdate"</Path>
                    <WillReboot>Always</WillReboot>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <Description>LL:Installing Windows Updates - Run 2</Description>
                    <Path>PowerShell -executionpolicy bypass -Command "start-windowsupdate"</Path>
                    <WillReboot>Always</WillReboot>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>4</Order>
                    <Description>LL:Execute Audit Mode script</Description>
                    <Path>PowerShell -executionpolicy bypass -Command "c:\windows\setup\scripts\startauditmode.ps1"</Path>
                    <WillReboot>Always</WillReboot>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
    <settings pass="auditSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <AutoLogon>
                <Enabled>true</Enabled>
                <LogonCount>5</LogonCount>
                <Username>administrator</Username>
                <Password>
                    <Value>aABhAC4ANwBmAHoANgApAFAAagB3AHAAIQBxACUAYwA7AFMALQB9AFYANQBQAGEAcwBzAHcAbwByAGQA</Value>
                    <PlainText>false</PlainText>
                </Password>
            </AutoLogon>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>aABhAC4ANwBmAHoANgApAFAAagB3AHAAIQBxACUAYwA7AFMALQB9AFYANQBBAGQAbQBpAG4AaQBzAHQAcgBhAHQAbwByAFAAYQBzAHMAdwBvAHIAZAA=</Value>
                    <PlainText>false</PlainText>
                </AdministratorPassword>
            </UserAccounts>
            <TimeZone></TimeZone>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:c:/win11-unattend/sources/install.wim#Windows 11 Enterprise" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
"@

$SysprepXml = [xml] @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <ProtectYourPC>3</ProtectYourPC>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideEULAPage>true</HideEULAPage>
            </OOBE>
            <RegisteredOrganization>Linklaters</RegisteredOrganization>
            <RegisteredOwner>Linklaters User</RegisteredOwner>
            <TimeZone>UTC</TimeZone>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:c:/win11-unattend/sources/install.wim#Windows 11 Enterprise" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
'@

foreach ($setting in $SysprepXml.Unattend.Settings) {
    #Write-host "Checking Setting:$($setting) in Unattend"
    foreach ($component in $setting.Component) {
        #write-host "Checking component:$($component) in Unattend"
        if ((($setting.'Pass' -eq 'oobeSystem') -or ($setting.'Pass' -eq 'specialize')) -and ($component.'Name' -eq 'Microsoft-Windows-International-Core')) {
            #Write-Host "Updating Locale settings"
            $component.InputLocale = $userlocale
            #$component.SystemLocale = $SysLocale
            #$component.UILanguage = $SysLocale
            #$component.UserLocale = $SysLocale
        }
        if ((($setting.'Pass' -eq 'oobeSystem') -or ($setting.'Pass' -eq 'specialize')) -and ($component.'Name' -eq 'Microsoft-Windows-Shell-Setup')) {
            #Write-Host "Updating Locale settings"
            $component.Timezone = $Timezone
        }
    } #end foreach setting.Component
} #end foreach unattendXml.Unattend.Settings

$CPLXML = [xml] @"
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
<gs:UserList>
    <gs:User UserID="Current" CopySettingsToDefaultUserAcct="true" CopySettingsToSystemAcct="true"/> 
</gs:UserList>
  <gs:UserLocale>
    <gs:Locale Name="$userlocale" SetAsCurrent="true" ResetAllSettings="false" />
  </gs:UserLocale>
 <gs:LocationPreferences> 
        <gs:GeoID Value="$GeoID"/> 
    </gs:LocationPreferences>
</gs:GlobalizationServices>
"@

$AuditModeXml.save($AuditModeXMLPath)
$SysprepXml.Save($SysprepXMLPath)
$SysprepXml.Save($RecoveryXMLPath)
$CPLXML.Save($IntlCPLXMLPath)
