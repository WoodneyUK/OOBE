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
	ValueNew = 'Enable'
 	ValueOld = 'Enabled'
	}

[pscustomobject]@{
	Setting = 'WindowsUEFIFirmwareUpdate'
	ValueNew = 'Enable'
 	ValueOld = 'Enabled'
	}

[pscustomobject]@{
	Setting = 'MACAddressPassThrough'
	ValueNew = 'Enable'
 	ValueOld = 'Enabled'
	}

[pscustomobject]@{
	Setting = 'PhysicalPresenceForTpmClear'
	ValueNew = 'Disable'
 	ValueOld = 'Disabled'
	}

[pscustomobject]@{
	Setting = 'SecureBoot'
	ValueNew = 'Enable'
 	ValueOld = 'Enabled'
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
       		wpeutil reboot 
   	}
    	Else {
     		Write-Host "This is for testing only.  Production devices MUST have a BIOS supervisor password" -ForegroundColor Yellow -Backgroundcolor DarkGray
        	pause
	}
}
Else{ 
    
    # Use WMIOpCodeInterface to specify SuperVisor Password
    # https://docs.lenovocdrt.com/ref/bios/wmi/wmi_guide/#password-authentication
    #
    $returnOP = (gwmi -class Lenovo_WmiOpcodeInterface -Namespace root\WMI).WmiOpCodeInterface("WmiOpCodePasswordAdmin:$CurrentPW") | select Return -ExpandProperty Return
    #Write-Host "ReturnOp [$($returnOp)]"
    If($returnOP -eq "Success"){
	Write-Verbose "BIOS WMI interface connection successful"
      	$modernbios = $TRUE
    }ElseIf ($returnOP -eq "Access Denied"){
    	#BIOS password is wrong
	Write-Warning "BIOS WMI interface connection unsuccessful due to Incorrect Password"
 	Write-Warning "This script cannot update the settings automatically"
  	Write-Warning "********************************************************************"
   	Write-Warning "**  Please set BIOS supervisor password to the known correct one  **"
        Write-Warning "**         Contact EUDM team for details of this password         **"
	Write-Warning "********************************************************************"
 	$continue = Read-Host -prompt "Press any key to reboot, or type CONTINUE to skip this"
        If ($continue -eq "CONTINUE"){
		Write-host "Incorrect BIOS supervisor password is only for testing"
  		$modernbios = $FALSE   #This will prompt to set individual settings manually if needed
   	}
	Else { wpeutil reboot }
    }Else{
        #BIOS is too old to support modern WMIopcodepassword
	Write-Warning "BIOS WMI interface connection unsuccessful"
 	Write-Warning "This script will not be able to update settings automatically"
      	$modernbios = $FALSE
    }    	
}
        
# Current BIOS Settings
$currentSettings = @(gwmi -class Lenovo_BiosSetting -namespace root\wmi | Where-Object { $_.CurrentSetting.split(",", [StringSplitOptions]::RemoveEmptyEntries) } | select -expandproperty currentsetting)


# Change BIOS settings
$BIOS = Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi 
If ($BIOS) {Write-Verbose "WMI Bios connection response:[$($BIOS.active)]"}

ForEach($Settings in $Get_Settings)
    {
        
        $MySetting = $Settings.Setting
        $ValueNew = $Settings.ValueNew
	    $ValueOld = $Settings.ValueOld

        $currentsetting = gwmi -class Lenovo_BiosSetting -namespace root\wmi | Where-Object { $_.CurrentSetting.split(",", [StringSplitOptions]::RemoveEmptyEntries) -eq $MySetting } | select currentsetting -ExpandProperty currentsetting
        
        If (-not $currentsetting) { Write-Host "[$($MySetting)] not found in this BIOS, skipping" }
        Else {
            $currentvalue = ($currentsetting -split "[,;]")[1]
        
            Write-Verbose "[$($MySetting)] returned value [$($currentvalue)]" 

            If (($currentvalue -eq $ValueNew) -or ($currentvalue -eq $ValueOld)){
                Write-Host "[$($MySetting)] is already set to [$($ValueNew)], no change needed" -ForegroundColor Green
            }
            Else
            {
        
	        $SaveNeeded = $true		
                #$Change_Return_Code = $BIOS.SetBiosSetting("$MySetting,$ValueNew,$CurrentPW,ascii,us").Return

	        Write-Host "Attempting to write setting [$($MySetting)] with value [$($ValueNew)]"
     		
     	    $Change_Return_Code = $BIOS.SetBiosSetting("$MySetting,$ValueNew").Return

	        write-verbose "BIOS Returned Response [$($Change_Return_Code)]"
 
            If(($Change_Return_Code) -eq "Invalid Parameter"){
                    #Its probably a OldSkool BIOS, so give it a try
                    Write-verbose "Retrying with Old Skool Bios method"
		            $Change_Return_Code = $BIOS.SetBiosSetting("$MySetting,$ValueOld,$CurrentPW,ascii,us").Return
                }

            If(($Change_Return_Code) -eq "Success")        								
                {
                If ($modernbios -eq $FALSE) {Write-Host "*********************"}
		        Write-Host "New value for [$($MySetting)] is [$($ValueNew)]" -ForegroundColor Yellow -Backgroundcolor DarkGray
      		    If ($modernbios -eq $FALSE) {Write-Host "*********************"}
                    }
                Else
                    {
                    Write-Warning "Cannot change setting [$($MySetting)] (Return code [$($Change_Return_Code)])"  											
		            Write-Warning "You must set this manually"
      		        $ManualSetBIOS = $TRUE
		        }
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
  	$continue = Read-Host -prompt "Press any key to reboot, or type CONTINUE to skip this"
        If ($continue -eq "CONTINUE"){
		Write-host "Incorrect BIOS settings is only for testing"
     	}
	Else { wpeutil reboot }	
    
    	#pause
    	#wpeutil reboot
}
