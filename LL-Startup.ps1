## Basic Menu
Clear-Host
write-host "USB Prod/Dev scripts selection"
write-host "------------------------------"
Write-Host "1 - [DEFAULT] Use Prod Script (From Azure)"
Write-Host "2 - Engineering Team only - Use Dev (from Github)"
Write-Host "Q - quit and restart"
write-host "Note :  This is where deploy scripts run from and does not affect Windows DEV/PrePROD/PROD ring" 
$selection = Read-Host "Enter selection [1,2,Q]"

If ($selection -eq 'q') {
    Write-Host "restarting"
    start-sleep 5
    wpeutil reboot
}ElseIf ($selection -eq  '2') {
    $Global:ScriptRootURL = "https://raw.githubusercontent.com/WoodneyUK/OOBE/main"
}Else{
    $Global:ScriptRootURL = "https://st2uupbw11seuwq01.blob.core.windows.net/oobe"
}

 
Write-Host "Setting URL to [$($ScriptRootURL)]"
Invoke-RestMethod -uri "$($ScriptRootURL)\startup.ps1" | out-file $env:temp\startup.ps1 -force -encoding ascii
& $env:temp\startup.ps1
