##  Script runs in WINPE
# Requires copy of C:\Windows\System32\Linklaters\Engineering\Lang\[lang].xml to be present in c:\recovery\OEM\lang
# Requires copy of C:\Windows\System32\Linklaters\Engineering\UsersRegionAndCultureCountry.Config to be present in c:\recovery\OEM\lang


$ResetConfigXMLPath = "c:\Recovery\OEM\ResetConfig.xml"   # used during the setup as part of OSDCloud
$ResetScriptPath = "c:\Recovery\OEM\copyfiles.cmd"
$result = New-Item c:\recovery\OEM -ItemType Directory -Force

$ResetConfigXml = [xml] @"
<?xml version="1.0" encoding="utf-8"?>
<!-- ResetConfig.xml -->
   <Reset>   
      <Run Phase="BasicReset_AfterImageApply">
         <Path>CopyFiles.cmd</Path>
         <Duration>2</Duration>
      </Run>
      <!-- May be combined with Recovery Media Creator
       configurations – insert SystemDisk element here -->
   </Reset>
"@

$CopyFiles = @"
rem Define %TARGETOS% as the Windows folder (This later becomes C:\Windows) 
for /F "tokens=1,2,3 delims= " %%A in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RecoveryEnvironment" /v TargetOS') DO SET TARGETOS=%%C

rem Define %TARGETOSDRIVE% as the Windows partition (This later becomes C:)
for /F "tokens=1 delims=\" %%A in ('Echo %TARGETOS%') DO SET TARGETOSDRIVE=%%A

xcopy "%TARGETOSDRIVE%\Recovery\OEM\Lang\*.xml" "%TARGETOS%\system32\Linklaters\Engineering\Lang1"
xcopy "%TARGETOSDRIVE%\Recovery\OEM\Lang\Country.config" "%TARGETOS%\system32\Linklaters\Engineering\UsersRegionAndCulture1"
"@

$ResetConfigXml.Save($ResetConfigXMLPath)
$CopyFiles | out-file $ResetScriptPath -Force -encoding ascii
