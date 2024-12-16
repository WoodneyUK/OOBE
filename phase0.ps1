# Create Wallpaper .jpg
$base64 = @'
'@
$PicPath = "C:\Windows\System32\Linklaters"
If (-not(Test-path $picpath)) { New-Item -Path $PicPath -ItemType Directory -force }
$Picfile = Join-path -path $PicPath -childpath Phase0.jpg
[byte[]]$Bytes = [convert]::FromBase64String($Base64)
[System.IO.File]::WriteAllBytes($Picfile,$Bytes)

# Connect to Offline Reg
Write-Host "writing to offline registry"
$RegistryHivePath = "c:\Windows\System32\config\SOFTWARE"
reg load "HKLM\NewOS" $RegistryHivePath 
Start-Sleep -Seconds 5

# Set LockScreenImage reg
$RegistryKey = "HKLM:\NewOS\Microsoft\Windows\CurrentVersion\PersonalizationCSP" 
$Result = New-Item -Path $RegistryKey -Force
$Result.Handle.Close()
$Result = New-ItemProperty -Path $RegistryKey -Name 'LockScreenImagePath' -PropertyType String -Value $Picfile -Force
$Result = New-ItemProperty -Path $RegistryKey -Name 'LockScreenImageUrl' -PropertyType String -Value $Picfile -Force
$Result = New-ItemProperty -Path $RegistryKey -Name 'LockScreenImageStatus ' -PropertyType DWord -Value 1 -Force

# Unload Reg
Remove-Variable Result
Get-Variable *Registry* | Remove-Variable
Start-Sleep -Seconds 5

# Unload the registry hive
Set-Location X:\
reg unload "HKLM\NewOS"