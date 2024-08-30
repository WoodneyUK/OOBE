##  Script runs in full Windows11 Audit mode

try { stop-transcript }
catch { Write-host "Transcript not running"}

new-item c:\windows\system32\linklaters\logs -itemtype directory -force

copy-item -path c:\osdcloud\logs\*.* -destination c:\windows\system32\linklaters\logs -recurse

remove-item c:\osdcloud -force -recurse
