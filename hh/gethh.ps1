Write-Host "Running Get Hardware Hash script"

$USBBootVol = get-volume | where-object {$_.filesystemlabel -match 'WINPE'}
$USBDataVol = get-volume | where-object {$_.filesystemlabel -match 'OSDCloud'}

$outputfolder = "$USBDataVol:\HardwareHashes"
new-item $outputfolder -ItemType directory -Force

$hashfolder = "$USBDataVol:\osdcloud\hardwarehash"
new-item $hashfolder -ItemType directory -Force

If ((test-path $outputfolder) -and (test-path $hashfolder) -ne $true) {
    Write-Warning "Unable to create working folders, exiting"
    break
    }

Push-Location $hashfolder

$Serial = $(Get-WmiObject win32_bios).SerialNumber
if ($Serial.Contains(" ")) { $Serial = $Serial -replace " ", "" }
$outputfile = "$outputfolder\$serial.csv"

#Run OA3Tool
&$hashfolder\oa3tool.exe /Report /ConfigFile=$hashfolder\OA3.cfg /NoKeyCheck

#Check if Hash was found
If (Test-Path $hashfolder\OA3.xml) 
{

#Read Hash from generated XML File
[xml]$xmlhash = Get-Content -Path "$hashfolder\OA3.xml"
$hash=$xmlhash.Key.HardwareHash

#Delete XML File
del $hashfolder\OA3.xml


# Initialize empty list
$computers = @()
$product=""

$computers = @()
# Create a pipeline object
$c = New-Object psobject -Property @{
	"Device Serial Number" = $serial
	"Windows Product ID" = $product
	"Hardware Hash" = $hash
}

$c | Select "Device Serial Number", "Windows Product ID", "Hardware Hash" | ConvertTo-CSV -NoTypeInformation | % {$_ -replace '"',''} | Out-File $OutputFile

Write-Host "HardwareHash has been saved as [$($outputfile)]"

} else {
write-warning "Error Generating HardwareHash"
}

Pop-Location

pause
