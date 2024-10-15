##  Script runs in WINPE

[CmdletBinding()]
    param (
        [String]$userlocale = "en-US",
        [String]$TimeZone = 'Eastern Standard Time'
    )

$SysLocale = "en-US"

write-host "UserLocale:$($userlocale)"
Write-host "SystemLocale:$($SysLocale)"
Write-host "TimeZone:$($TimeZone)"

$auditmodescript = "$($Global:ScriptRootURL)/StartAuditMode.ps1"
$XMLPath = "c:\windows\panther\unattend\unattend.xml"
$OOBEPath = "c:\windows\panther\unattend\oobe.xml"

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
                <ProtectYourPC>3</ProtectYourPC>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideEULAPage>true</HideEULAPage>
            </OOBE>
            <RegisteredOrganization>Linklaters</RegisteredOrganization>
            <RegisteredOwner>Linklaters User</RegisteredOwner>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:c:/win11-unattend/sources/install.wim#Windows 11 Enterprise" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
'@

$boottowindows = [xml] @"
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
    <settings pass="specialize">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="wow64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SystemLocale>en-US</SystemLocale>
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
            <TimeZone>$TimeZone</TimeZone>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:c:/win11-unattend/sources/install.wim#Windows 11 Enterprise" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
"@


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


$unattendXml.Save($OOBEPath)
$boottowindows.save($xmlpath)
