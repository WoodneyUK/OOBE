(Get-Date) | out-file c:\osdcloud\testfromPS.txt -force

# net user administrator /active:yes

set-executionpolicy remotesigned -force

import-module osd

start-windowsupdate
