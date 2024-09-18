##  Script runs in WINPE

$Get_Manufacturer_Info = (Get-WmiObject win32_computersystem).Manufacturer
If($Get_Manufacturer_Info -notlike "*lenovo*")	
	{
		Write-Output "Device manufacturer not supported"
		EXIT 1			
	}

## Read Passwords
[Byte[]]$key = (1..16)
$json = Invoke-restmethod -uri "$($Global:ScriptRootURL)/biossec.json"
$CurrentPW = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(($json.CurrentPassword | ConvertTo-SecureString -key $key)))
$OldPWArray = @()
ForEach($OldSecPW in $Json.OldPasswords.OldPasswords){
    $OldPW = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(($OldSecPW | ConvertTo-SecureString -key $key)))
    #$SecureOldPassword = ($OldPassword | ConvertTo-SecureString -AsPlainText -Force) | ConvertFrom-SecureString -Key $key 
    $OldPWArray += $OldPW
}

# Define custom settings
$Get_Settings = @(
[pscustomobject]@{
	Setting = 'BIOSUpdateByEndUsers'
	Value = 'Enable'
	}

[pscustomobject]@{
	Setting = 'WindowsUEFIFirmwareUpdate'
	Value = 'Enable'
	}

[pscustomobject]@{
	Setting = 'MACAddressPassThrough'
	Value = 'Enable'
	}

[pscustomobject]@{
	Setting = 'PhysicalPresenceForTpmClear'
	Value = 'Disable'
	}

[pscustomobject]@{
	Setting = 'SecureBoot'
	Value = 'Enable'
	}
 
)

$BIOSPWStatus = gwmi win32_computersystem | select adminpasswordstatus -expandproperty adminpasswordstatus
If ($BIOSPWStatus -eq 0) {
	cls
 	write-warning "IMPORTANT : BIOS Supervisor Password is not set"
	write-warning "This process will not continue"
 	Write-Warning "Please reboot into BIOS by pressing F1 at the startup screen"
  	write-Warning "And enable the standard BIOS Supervisor password."
   	write-Warning "Contact EUDM team for details of the BIOS Supervisor password"
	$BIOSinput = read-host -Prompt "Computer will now restart, unless you type CONTINUE"

	If ($BIOSinput -ne "CONTINUE"){ 
 		Write-host "now restarting..."
       		restart-computer -force
    		start-sleep 5  
   	}
    	Else {
     		Write-Host "This is for testing only.  Production devices should have a BIOS supervisor password"
        	pause
	}
}
Else{ 
    
    # Use WMIOpCodeInterface to specify SuperVisor Password
    # https://docs.lenovocdrt.com/ref/bios/wmi/wmi_guide/#password-authentication
    #
    $returnOP = (gwmi -class Lenovo_WmiOpcodeInterface -Namespace root\WMI).WmiOpCodeInterface("WmiOpCodePasswordAdmin:$CurrentPW") | select Return -ExpandProperty Return
    If(($returnOP) -eq "Success"){
	Write-Host "BIOS WMI interface connection successful"
      	$modernbios = $TRUE
    }Else{
        #BIOS is too old to support modern WMIopcodepassword
	Write-Warning "BIOS WMI interface connection unsuccessful"
 	Write-Warning "This script will not be able to update settings automatically"
      	$modernbios = $FALSE
    }    	
}
        
# Current BIOS Settings
$currentSettings = gwmi -class Lenovo_BiosSetting -namespace root\wmi | Where-Object { $_.CurrentSetting.split(",", [StringSplitOptions]::RemoveEmptyEntries) } | select currentsetting

# Change BIOS settings
$BIOS = Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi 
ForEach($Settings in $Get_Settings)
    {
        
        $MySetting = $Settings.Setting
        $NewValue = $Settings.Value

        $currentsetting = gwmi -class Lenovo_BiosSetting -namespace root\wmi | Where-Object { $_.CurrentSetting.split(",", [StringSplitOptions]::RemoveEmptyEntries) -eq $MySetting } | select currentsetting -ExpandProperty currentsetting
        $currentvalue = ($currentsetting -split ",")[1]
        
        If ($currentvalue -eq $NewValue){
            Write-Host "[$($MySetting)] is already set to [$($NewValue)], no change needed" -ForegroundColor Green -Backgroundcolor DarkGray
        }
        Else
        {
        
	 	$SaveNeeded = $true		
            $Change_Return_Code = $BIOS.SetBiosSetting("$MySetting,$NewValue").Return

            If(($Change_Return_Code) -eq "Success")        								
                {
                    If ($modernbios -eq $FALSE) Write-Host "*********************"
		    Write-Host "New value for [$($MySetting)] is [$($NewValue)]" -ForegroundColor Yellow -Backgroundcolor DarkGray
      		    If ($modernbios -eq $FALSE) Write-Host "*********************"
                }
            Else
                {
                    Write-Warning "Cannot change setting [$($MySetting)] (Return code [$($Change_Return_Code)])"  											
		    Write-Warning "You must set this manually"
      		    $ManualSetBIOS = $TRUE
		}
        }								
    }



# Save BIOS change part
If (($SaveNeeded -eq $true) -and ($ManualSetBIOS -ne $TRUE) -and ($modernbios -eq $TRUE)){
    $Save_BIOS = (Get-WmiObject -class Lenovo_SaveBiosSettings -namespace root\wmi)
    $Save_Change_Return_Code = $SAVE_BIOS.SaveBiosSettings().Return		
    If(($Save_Change_Return_Code) -eq "Success")
	    {
		    Write-Host "BIOS settings have been saved"																
	    }
    Else
	    {
		    Write-Warning "An issue occured while saving changes - $($Save_Change_Return_Code)"										
	    }
}
elseif (($ManualSetBIOS -eq $TRUE) -or (($modernbios -eq $FALSE) -and ($SaveNeeded -eq $true))){
	Write-Warning "You MUST now reboot and press F1 to enter the BIOS and set the above settings manually"
 	Write-Warning "These must be set before Continuing to install Windows"
  	Write-Warning "This PC will now reboot"
   	pause
    	wpeutil reboot
}
