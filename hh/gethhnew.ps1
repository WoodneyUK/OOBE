#region Vars and Initialise
$HashInbox = 'PATH TO WHERE YOU WANT TO PUT THE HASH FILE'
$stupiddir = 'C:\HWID'
$null = New-Item $stupiddir -ItemType Directory -Force
$HashFile = "$stupiddir\$((Get-WmiObject -Class Win32_BIOS).SerialNumber).csv"
#endregion Vars and Initialise

#region Generate Hardware Hash
try
    {
    Push-Location
    Set-Location -Path "C:\HWID"
    $session = New-CimSession
    $serial = (Get-CimInstance -CimSession $session -Class Win32_BIOS).SerialNumber
    $devDetail = (Get-CimInstance -CimSession $session -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'")
    $hash = $devDetail.DeviceHardwareData
    $c = New-Object psobject -Property @{
	    "Device Serial Number" = $serial
	    "Windows Product ID" = $product
	    "Hardware Hash" = $hash
	    }
    $c | Select "Device Serial Number", "Windows Product ID", "Hardware Hash", "Group Tag" | ConvertTo-CSV -NoTypeInformation | % {$_ -replace '"',''} | Out-File $HashFile -Force
    Remove-CimSession $session
    Pop-Location
    }
catch
    {
    'Unable to generate hardware hash'
    }

#endregion Generate Hardware Hash

#region Add GroupTag if required
if($GroupTag)
    {
    #Add the Group Tag to the hash file if required
    $HWID = Import-csv $HashFile
    $HWID = $HWID | Select-Object -Property *, @{label = 'Group Tag'; expression = {$GroupTag}}
    $HWID | Export-Csv -Path $HashFile -NoTypeInformation -Encoding Unicode
    #Remove quotes that are not supported, and ensure correct encoding
    $HWIDquotes = Get-Content $HashFile
    $HWIDquotes.Replace('","',",").TrimStart('"').TrimEnd('"') | Out-File $HashFile -Force -Confirm:$false
    }
#endregion Add GroupTag if required

#region Copy hash file to 'somewhere'
Try
    {
    Copy-Item $HashFile -Destination $HashInbox -Force -ErrorAction Stop
    #Remove it locally
    $null = Remove-Item $stupiddir -Force -Recurse
    }
catch
    {
    "Unable to copy [$($HashFile)] to [$($HashInbox)]"
    }
#endregion Copy hash file to automation service \ $HashInbox
