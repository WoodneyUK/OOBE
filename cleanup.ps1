##  Script runs in full Windows11 Audit mode

try { stop-transcript }
catch { Write-host "Transcript not running"}

new-item C:\Windows\System32\Linklaters\Logfiles -itemtype directory -force

copy-item -path c:\osdcloud\logs\*.* -destination C:\Windows\System32\Linklaters\Logfiles -recurse

Get-ChildItem -Path c:\osdcloud -Recurse | Remove-Item -force -recurse
remove-item c:\osdcloud -force
