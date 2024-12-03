##  Script runs in WINPE

$ResetConfigXMLPath = "c:\windows\panther\unattend\unattend.xml" # used during the setup as part of OSDCloud

$result = New-Item c:\recovery\autoapply -ItemType Directory -Force

$ResetConfigXml = [xml] @"
<?xml version="1.0" encoding="utf-8"?>
<!-- ResetConfig.xml -->
   <Reset>
      <Run Phase="BasicReset_BeforeImageApply">
         <Path>SaveLogFiles.cmd</Path>
         <Duration>4</Duration>
      </Run>      
      <Run Phase="BasicReset_AfterImageApply">
         <Path>RetrieveLogFiles.cmd</Path>
         <Duration>2</Duration>
      </Run>
      <!-- May be combined with Recovery Media Creator
       configurations – insert SystemDisk element here -->
   </Reset>
"@


$$ResetConfigXml.Save($ResetConfigXMLPath)
