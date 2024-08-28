$Get_Manufacturer_Info = (Get-WmiObject win32_computersystem).Manufacturer
If($Get_Manufacturer_Info -notlike "*lenovo*")	
	{
		Write-Output "Device manufacturer not supported"
		EXIT 1			
	}

## Read Passwords
[Byte[]]$key = (1..16)
$json = Invoke-restmethod https://raw.githubusercontent.com/WoodneyUK/OOBE/main/biossec.json
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
)

$BIOSPWStatus = gwmi win32_computersystem | select adminpasswordstatus -expandproperty adminpasswordstatus
If ($BIOSPWStatus -eq 0) {
	cls
 	write-warning "IMPORTANT : BIOS Supervisor Password is not set"
	write-warning "This process will not continue"
 	Write-Warning "Please reboot into BIOS by pressing F1 at the startup screen"
  	write-Warning "And enable the standard BIOS Supervisor password."
   	write-Warning "Contact EUDM team for details of the BIOS Supervisor password"
    write-Warning "This computer will now restart"
    pause
    restart-computer
    exit    
}
Else{ 
    
    # Use WMIOpCodeInterface to specify SuperVisor Password
    # https://docs.lenovocdrt.com/ref/bios/wmi/wmi_guide/#password-authentication
    #
    $returnOP = (gwmi -class Lenovo_WmiOpcodeInterface -Namespace root\WMI).WmiOpCodeInterface("WmiOpCodePasswordAdmin:$CurrentPW") | select Return -ExpandProperty Return
    If(($returnOP) -eq "Success")
	    {
		    Write-Host "BIOS SuperVisor Password is correct"																
	    }
    Else{
        #Wrong Password
        cls
 	    write-warning "IMPORTANT : A BIOS Supervisor Password is set, but is **WRONG**"
	    write-warning "This process will not continue"
 	    Write-Warning "Please reboot into BIOS by pressing F1 at the startup screen"
  	    write-Warning "And enable the standard BIOS Supervisor password."
   	    write-Warning "Contact EUDM team for details of the BIOS Supervisor password"
    	write-Warning "This computer will now restart"
    	pause
     	restart-computer
        exit
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
            Write-Host "$($MySetting) is already set to $($NewValue), no change needed"
        }
        Else
        {
        	$SaveNeeded = $true		
            $Change_Return_Code = $BIOS.SetBiosSetting("$MySetting,$NewValue").Return

            If(($Change_Return_Code) -eq "Success")        								
                {
                    Write-Host "New value for $($MySetting) is $($NewValue)"  											
                }
            Else
                {
                    Write-Warning "Cannot change setting $($MySetting) (Return code $($Change_Return_Code))"  											
                }
        }								
    }



# Save BIOS change part
If ($SaveNeeded -eq $true){
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
