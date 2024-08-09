$XMLPath = "c:\windows\panther\unattend\unattend.xml"

$UnattendXml = [xml] @'
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
                <Description>Set ExecutionPolicy Bypass</Description>
                <Path>PowerShell -WindowStyle Hidden -Command "Set-ExecutionPolicy Bypass -Force"</Path>
                </RunSynchronousCommand>

                <RunSynchronousCommand wcm:action="add">
                <Order>2</Order>
                <Description>WaitWebConnection</Description>
                <Path>PowerShell -Command "Wait-WebConnection powershellgallery.com -Verbose"</Path>
                </RunSynchronousCommand>

                <RunSynchronousCommand wcm:action="add">
                <Order>3</Order>
                <Description>Save Get-WindowsAutoPilotInfo</Description>
                <Path>PowerShell -Command "Install-Script -Name Get-WindowsAutoPilotInfo -Verbose -Force"</Path>
                </RunSynchronousCommand>
                
                <RunSynchronousCommand wcm:action="add">
                <Order>4</Order>
                <Description>Start Windows Updates</Description>
                <Path>PowerShell -Command "start-windowsupdate" -windowstyle maximized</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
</unattend>
'@

md c:\windows\panther\unattend -Force

$UnattendXml.Save($XMLPath)
