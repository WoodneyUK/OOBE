##  Script runs in full Windows 11

$connection = Get-Content "C:\OSDCloud\configs\WiFi.JSON" -raw | Convertfrom-json

Get-ChildItem c:\osdcloud\configs\*.xml | foreach {
    netsh wlan add profile filename="$_."
    [xml] $import = Get-Content $_
    If ($connection.Addons.SSID -eq $import.wlanprofile.ssidconfig.ssid.name){
        netsh wlan connect name=$($import.wlanprofile.name) SSID=$($import.wlanprofile.ssidconfig.ssid.name)
    }
}

start-sleep 30
