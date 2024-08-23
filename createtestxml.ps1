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
                <ProtectYourPC>3</ProtectYourPC>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideEULAPage>true</HideEULAPage>
            </OOBE>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:c:/win11-unattend/sources/install.wim#Windows 11 Enterprise" xmlns:cpi="urn:schemas-microsoft-com:cpi" />
</unattend>
'@

$boottowindows = [xml] @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Reseal>
                <Mode>Audit</Mode>
            </Reseal>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="wow64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SystemLocale>en-US</SystemLocale>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="wow64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideLocalAccountScreen>true</HideLocalAccountScreen>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <ProtectYourPC>3</ProtectYourPC>
            </OOBE>
        </component>
    </settings>
    <settings pass="auditUser">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Description>LL:Set ExecutionPolicy Bypass</Description>
                    <Path>PowerShell -WindowStyle Hidden -Command "Set-ExecutionPolicy Bypass -Force"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <Description>LL:WaitWebConnection</Description>
                    <Path>PowerShell -Command "Wait-WebConnection powershellgallery.com -Verbose"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <Description>LL:Download Audit Mode script</Description>
                    <Path>PowerShell -Command "Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/startAuditMode.ps1 | out-file "c:\Windows\system32\Linklaters\OOBE\startAuditMode.ps1" -force -encoding ascii"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>4</Order>
                    <Description>LL:Installing Windows Updates</Description>
                    <Path>PowerShell -Command "start-windowsupdate"</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>5</Order>
                    <Description>LL:Execute Audit Mode script</Description>
                    <Path>PowerShell -Command "c:\Windows\system32\Linklaters\OOBE\startAuditMode.ps1"</Path>
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
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="wow64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <AutoLogon>
                <Password>
                    <Value>P@55w0rd</Value>
                    <PlainText>true</PlainText>
                </Password>
                <LogonCount>5</LogonCount>
                <Enabled>true</Enabled>
                <Username>administrator</Username>
            </AutoLogon>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>P@55w0rd</Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
            </UserAccounts>
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

#$unattendXml.Save($XMLPath)
$boottowindows.save($xmlpath)
