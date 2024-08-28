$Get_Manufacturer_Info = (Get-WmiObject win32_computersystem).Manufacturer
If($Get_Manufacturer_Info -notlike "*lenovo*")	
	{
		Write-Output "Device manufacturer not supported"
		EXIT 1			
	}


# Define custom settings
$Get_Settings = @(
[pscustomobject]@{
    Setting = 'BootOrder'
    Value = 'NVMe0:USBHDD'
    }

[pscustomobject]@{
    Setting = 'BootOrderLock'
    Value = 'Enable'
    }
	
[pscustomobject]@{
	Setting = 'UserPresenceSensing'
	Value = 'Disable'
	}

[pscustomobject]@{
	Setting = 'BIOSUpdateByEndUsers'
	Value = 'Enable'
	}

[pscustomobject]@{
	Setting = 'WindowsUEFIFirmwareUpdate'
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
    	write-Warning "This computer will now restart"
    	pause
     	restart-computer
}
Else	{ Write-Host "BIOS password is set"}


# Change BIOS settings
$BIOS = Get-WmiObject -Class Lenovo_SetBiosSetting -Namespace root\wmi 
ForEach($Settings in $Get_Settings)
    {
        $MySetting = $Settings.Setting
        $NewValue = $Settings.Value				
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

# Save BIOS change part
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
