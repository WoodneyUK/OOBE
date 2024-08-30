##  Script runs in WINPE

$code=@'
<!--
  --Filename: 		ThinkBiosConfig.hta
  --Author: 		Devin McDermott
  --Version:		1.41
  --Description:	This application allows system administrators to easily edit the BIOS settings
						on a local or remote computer through the command line or graphical interface.
  -->
<html id="main">
	<head>
		<title>Think BIOS Configurator</title>
		
		<HTA:APPLICATION
			APPLICATIONNAME="Think BIOS Configurator"
			SCROLL="yes"
			SINGLEINSTANCE="no"
			ID="objTBCHTA"
			BORDER="thin"
			BORDERSTYLE="normal"
		>
		<style>

			body {
				font-family: "Segoe UI", Arial, Helvetica, sans-serif;
				font-size: 12px;
			}
			
			.sections {
				font-size: 150%;
			}
			
			.titlebar {
				padding: 14px;
				margin-bottom: 10px;
				color:black;
				background-color:white;
				border: 4px solid #3498db;

			}

			#title {
				display: inline;
				font-size: 180%;
				font-weight: bold;
				text-align: center;
				vertical-align: center;
				float: center;
			}

			.fileactions {
				text-align:left;
				padding:8px;
				background-color:white;
				border: 1px solid black;
				margin-bottom: 10px;
				font-size: 1em;
			}

			.btn {
			  background: #3498db;
			  color: #ffffff;
			  padding: 8px;
			  text-decoration: none;

			}

			.btn:hover {
			  background: #3cb0fd;
			  text-decoration: none;
			}

			.file {
				padding: 8px;
				background: white;
			}

			td {
				font-size: 80%;
			}
						
			select {
				font-size: 80%;
			}

			#security {
				padding:6px;
				background-color:white;
				width:100%;
				border: 1px solid black;
				margin-bottom: 10px;
			}

			#security label {margin-left:16px;margin-right:16px;}
			#security select {width:120px;}

			#security_actions {
				width:100%;
			}
			#targeting_div {
				padding:6px;
				background-color:white;
				width:100%;
				border: 1px solid black;
				margin-bottom: 10px;
			}

			.result-table {
			    font-family: "Segoe UI", Arial, Helvetica, sans-serif;
				width: 1em;
				border-collapse: collapse;
			}

			.result-table td {
				border: 1px solid #3498db;
				padding: 16px 20px 16px 20px;

			}

			.result-table select {
				font-family: "Segoe UI", Arial, Helvetica, sans-serif;
				font-size: 90%;
			}

			.logobox {
				vertical-align: top;
				float:right;
				width: 320px;
				height: 40px;
				border: none;
			}

			.logobox:hover {
				border: 1px solid #3498db;
				cursor: pointer;
			}
			.lenovo{
				font-family: helvetica;
				font-size: 100%;
				font-weight: bold;
				width: 100px;
				background-color: #3498db;
				color: white;
				display: inline;
				margin-right: 10px;
				padding: 10px;
				text-align: center;
			}

			.lenovo:hover {
				cursor: pointer;
			}

			.cdrt{
				width: 200px;
				display: inline;
				font-family: helvetica;
				font-size: 60%;
				text-align: center;
			}

		</style>
	</head>

	<script language="VBScript">
		Option Explicit

		Dim gCurrentSettings : Set gCurrentSettings = CreateObject("Scripting.Dictionary")
		Dim gChangedSettings : Set gChangedSettings = CreateObject("Scripting.Dictionary")
		Dim gNetworkArray()

		Dim objShell : Set objShell = CreateObject("WScript.Shell")
		Dim myCur : myCur = objShell.CurrentDirectory
		Set objShell = Nothing

		Dim gTargetComputerName : gTargetComputerName = "LOCALHOST"
		Dim gTargetComputerModel : gTargetComputerModel = ""
		Dim gRemoteCommand : gRemoteCommand = ""
		Dim gPwd : gPwd = ""
		Dim gRefresh : gRefresh = False
		Dim gFirstRun : gFirstRun = True
		Dim gTargetDifferentComputer : gTargetDifferentComputer = False
		Dim gIsALaptop : gIsALaptop = False
		Dim gValueList : gValueList = ""
		Dim gUsername : gUsername = ""
		Dim gPassword : gPassword = ""
		Dim gCanUseComplexPassword : gCanUseComplexPassword = False													 
		Dim gDifferentUser : gDifferentUser = False
		Dim gCurrentDirectory
		Dim gModifiedBootOrder : gModifiedBootOrder = False
		Dim gLogLocation
		Dim gSerialNumber : gSerialNumber = ""
		Dim gModelType : gModelType = ""
		Dim gSupervisorPassword : gSupervisorPassword = False
		Dim gErrorLevel : gErrorLevel = 0
		Dim gNoLog : gNoLog = False
		Dim gCanUseSMP : gCanUseSMP = "disabled"
		Dim gBiosVersion : gBiosVersion = ""
								  

		'---------------------------------------------------------
		'---------------------- Main Sub -------------------------
		'---------------------------------------------------------

		' The main program that runs on body load of the HTA
		' Dynamically fill the HTA with the WMI information
		Sub TestSub
			On Error Resume Next
			gTargetComputerModel = UpdateComputerModel

			If (gFirstRun = True) Then
				getNetworkAddresses
				gRefresh = True
				'TestElevation
				gFirstRun = False
			End If

			Dim colItems, StrItem, StrValue

			gChangedSettings.RemoveAll
			gCurrentSettings.RemoveAll

			WriteToLogFile("Gathering settings for " & gTargetComputerModel)
			Dim objWMIService : Set objWMIService = getWMIObject("\root\wmi")
			If Err = 0 Then

				If(determineLocalMachine(gTargetComputerName) = True) Then
					gTargetDifferentComputer = False
					toggleButtonOff "localButton"
				Else
					gTargetDifferentComputer = True
					toggleButtonOn "localButton"
				End If

				targeting.InnerHTML = "Accessing settings on <b><i>" & gTargetComputerName & " (" & gTargetComputerModel & ")</i></b>"

				Set colItems = objWMIService.ExecQuery("Select * from Lenovo_BiosSetting")

				Dim myHTML, objItem, count, color, rowSpan, bootOrderHtml
				myHTML = "<table class='result-table'><thead style='font-size:70%;font-weight:bold'><th>Setting</th><th>Value</th><th>Setting</th><th>Value</th></thead>"
				count = 0
				color = "#D3D3D3"
				rowSpan = 1

				For Each objItem in colItems
					If Len(objItem.CurrentSetting) > 0 And objItem.CurrentSetting <> "Reserved,Disable" Then
						StrItem = Left(ObjItem.CurrentSetting, InStr(ObjItem.CurrentSetting, ",") - 1)
						
						If(InStr(objItem.CurrentSetting, ";[Excluded from boot order") > 0) Then
							gModifiedBootOrder = True
						End If
						
						If(InStr(StrItem, "SystemManagementPassword") > 0) Then
							gCanUseSMP = ""
						End If
						If(InStr(objItem.CurrentSetting, ";") > 0) Then
							StrValue = extractString(ObjItem.CurrentSetting, InStr(ObjItem.CurrentSetting, ","), InStr(ObjItem.CurrentSetting, ";") - 1)
							Dim temp : temp = extractString(ObjItem.CurrentSetting, InStr(ObjItem.CurrentSetting, ";"), Len(ObjItem.CurrentSetting))
							gValueList = extractString(temp, InStr(temp, ":"), InStr(temp, "]") - 1)
							'msgbox temp
						Else
							StrValue = Mid(ObjItem.CurrentSetting, InStr(ObjItem.CurrentSetting, ",") + 1, 256)
						End If

						If (Not(gCurrentSettings.Exists(StrItem))) Then
							gCurrentSettings.add StrItem, StrValue
							If (StrItem = "BootOrder") Then
								'rowSpan = 3
								bootOrderHtml = "<td class='setting_label' id='" & (StrItem & "Text") & "'>" & replaceSymbols(StrItem) & "</td>" _
												& "<td colspan=2>" & CreatePicker(StrItem, StrValue, objWMIService) & "</td><td>&nbsp;</td></tr>"
							Else
								rowSpan = 1

								If (count mod 2 = 0) Then
									count = count + 1
									myHTML = myHTML & "<tr bgcolor='" & color & "'><td class='setting_label' rowspan='" & rowSpan & "' id='" & (StrItem & "Text") & "'>" & replaceSymbols(StrItem) & "</td>" _
													& "<td rowspan='" & rowSpan & "'>" & CreatePicker(StrItem, StrValue, objWMIService) & "</td>"
								Else
									myHTML = myHTML & "<td rowspan='" & rowSpan & "' class='setting_label' id='" & (StrItem & "Text") & "'>" & replaceSymbols(StrItem) & "</td>" _
													& "<td rowspan='" & rowSpan & "'>" & CreatePicker(StrItem, StrValue, objWMIService) & "</td></tr>"
									count = count + 1
									If (color = "#FFFFFF") Then
										color = "#D3D3D3"
									Else
										color = "#FFFFFF"
									End If
								End If
							End If
						End If
					End If
				Next
				If (color = "#FFFFFF") Then
					color = "#D3D3D3"
				Else
					color = "#FFFFFF"
				End If
			    myHTML = myHTML & "<tr bgcolor='" & color & "'>" & bootOrderHtml
				myHTML = myHTML & "			<tr>" _
				& "<td colspan='4'>" _
				& "	<center>" _
				& "		<input type='button' class='btn' id='saveButton' value='Save Changed Settings' name='save_button' onClick='SaveChanges'>" _
				& "		<input type='button' class='btn' value='Restore BIOS Defaults' name='default_button' onClick='SetDefaults'>" _
				& "		<input type='button' class='btn' id='resetButton' value='Reset to Current Settings' name='reset_button' onClick='ResetSub'>" _
				& "	</center>" _
				& "</td>" _
			& "</tr>"
				myHTML = myHTML & "<tr><td style='border:none'>&nbsp;</td><td style='border=none'>&nbsp;</td></tr></table>"
				dataArea.InnerHTML = myHTML
			Else
				DisplayErrorInfo
				LocalSub
			End If
		End Sub

		'---------------------------------------------------------
		'-------------------- Helper subs ------------------------
		'---------------------------------------------------------

		Sub WriteToLogFile(line)
			If (gNoLog = False) Then
				Dim objFSO, objFolder, objShell, objTextFile, objFile
				Dim strDirectory, strFile, strText
				
				strFile = gModelType & "_" & gSerialNumber & ".txt"

				' Create the File System Object
				Set objFSO = CreateObject("Scripting.FileSystemObject")

				' Check that the strDirectory folder exists
				If objFSO.FolderExists(gLogLocation) Then
					If Not objFSO.FileExists(gLogLocation & strFile) Then
					   Set objFile = objFSO.CreateTextFile(gLogLocation & strFile)
					End If 

					set objFile = nothing
					set objFolder = nothing
					' OpenTextFile Method needs a Const value
					' ForAppending = 8 ForReading = 1, ForWriting = 2
					Const ForAppending = 8

					Set objTextFile = objFSO.OpenTextFile(gLogLocation & strFile, ForAppending, True)

					' Writes strText every time you run this VBScript
					objTextFile.WriteLine(line)
					objTextFile.Close
				End If
			End If
		End Sub

		Sub CheckForBiosPassword
			Dim objItem
			Dim objWMIService : Set objWMIService = getWMIObject("\root\wmi")
			Dim colItems : Set colItems = objWMIService.ExecQuery("Select * From Lenovo_BiosPasswordSettings")
			
			For Each objItem in colItems
				Dim state : state = objItem.PasswordState
				If (state = "2" OR state = "3" OR state = "6" OR state = "7") Then
					gSupervisorPassword = True
				End If
			Next
		End Sub
		
		Function ComplexPasswordClassExists
			ComplexPasswordClassExists = False 
			Dim objWMIService: Set objWMIService = getWMIObject("\root\wmi")
			Dim colClasses: Set colClasses = objWMIService.SubclassesOf() 
			Dim objClass 
			For Each objClass In colClasses 
				if instr(objClass.Path_.Path,"Lenovo_WmiOpcodeInterface") Then 
					ComplexPasswordClassExists = True 
				End if 
			Next 
			Set objWMIService = Nothing 
			Set colClasses = Nothing 
		End Function 							 
					
		Sub TestElevation(args)
			Dim oShell, oExec, szStdOut
			szStdOut = ""
			Dim objWMIService : Set objWMIService = getWMIObject("\root\cimv2")
			Dim colItems : Set colItems = objWMIService.ExecQuery("Select * From Win32_OperatingSystem")
			Set objWMIService = Nothing
			Dim objItem, winPE
			winPE = False

			For Each objItem in colItems
				If (InStr(objItem.SystemDevice, "Ramdisk") > 0) Then
					winPE = True
				End If
			Next

			If (winPE <> True) Then
				Set oShell = CreateObject("WScript.Shell")
				Set oExec = oShell.Exec("whoami /groups")
				Do While (oExec.Status = 0)
					If Not oExec.StdOut.AtEndOfStream Then
						szStdOut = szStdOut & oExec.StdOut.ReadAll
					End if
				Loop

				Select Case oExec.ExitCode
					Case 0
						If Not oExec.StdOut.AtEndOfStream Then
							szStdOut = szStdOut & oExec.StdOut.ReadAll
						End If

						If Instr(szStdOut,"S-1-16-12288") Then
							Dim count : count = 0
							Set objWMIService = getWMIObject("\root\cimv2")
							Set colItems = objWMIService.ExecQuery("Select * From Win32_Process WHERE Name='mshta.exe'")
							For Each objItem in colItems
								Dim name : name = Ubound(Split(args, "\"))
								If (InStr(objItem.CommandLine, (Left(name,Len(name)-1))) > 0) Then
									count = count + 1
								End If
							Next

							If (count > 2) Then
								MsgBox "Please use the other open application."
								Window.close()
							End If
						Else
							If Instr(szStdOut,"S-1-16-8192") Then

								Dim shellApp : Set shellApp = CreateObject("Shell.Application")
								shellApp.ShellExecute "mshta.exe", args & " uac", "", "runas", 1
								'msgbox "Elevated!"
								'End the non-elevated instance
								Window.close()
							Else
								'msgbox "Unknown!"
							End If
						End If
					Case Else
						If Not oExec.StdErr.AtEndOfStream Then
							msgbox oExec.StdErr.ReadAll
						End If
				End Select
			End If
		End Sub

		' Finds the model that is being targeted
		' Going to use this to find the correct config
		Function UpdateComputerModel
			Dim objWMIService : Set objWMIService = getWMIObject("\root\cimv2")
			Dim colItems : Set colItems = objWMIService.ExecQuery("Select * From Win32_ComputerSystemProduct")
			Dim colChassis : Set colChassis = objWMIService.ExecQuery("SELECT * FROM Win32_SystemEnclosure")
			Dim colBios : Set colBios = objWMIService.ExecQuery("SELECT * FROM Win32_Bios")
			Set objWMIService = Nothing
			Dim objItem, objChassis, objBios
			Dim intType
			gIsALaptop = False
			UpdateComputerModel = ""
			CheckForBiosPassword
			For Each objBios in colBios
				gBiosVersion = objBios.SMBIOSBIOSVersion
			Next
			For Each objItem in colItems
				gSerialNumber = objItem.IdentifyingNumber
				gModelType = objItem.Name
				Dim model : model = objItem.Version
				Dim longname : longname = ""
				Dim word
				
				For Each objChassis in colChassis
					For Each intType in objChassis.ChassisTypes
						If(intType = 8 OR intType = 9 OR intType = 10 OR intType = 11 OR intType = 14 OR intType = 30 OR intType = 31 OR intType = 32) Then
							gIsALaptop = True
						End If
					Next
				Next
				
				If(InStr(model, " ")) Then
					longname = Split(model, " ")
					
					For Each word in longname
						If (word <> "ThinkPad" And word <> "ThinkCentre" And word <> "ThinkStation" And word <> "S1") Then
							UpdateComputerModel = UpdateComputerModel & word
						End If
					Next
				Else
					UpdateComputerModel = model
				End If
			Next
		End Function

		' See what file has been be picked by the user.
		' Toggle buttons accordingly
		Sub CheckFile
			If (InStr(file.value, ".") > 0) Then
				If (LCase(Mid(file.value, InStrRev(file.value, "."))) = ".ini") Then
					toggleButtonOn "configButton"
				End If
			Else
				toggleButtonOff "configButton"
			End If
		End Sub

		' Apply the configuration file that was selected
		Sub ApplyFile
			If(file.value <> "") Then
				If(doValidationSave) Then
					ParseFile file.value, gPwd
					TestSub
				End If
			End If
		End Sub

		'Creates a WMI object with the specified namespace
		'Different ways are needed if the user provides a username and password
		Function getWMIObject(namespace)
			If(gUsername = "" Or gPassword = "") Then
				Set getWMIObject=GetObject("WinMgmts:" _
								& "{ImpersonationLevel=Impersonate" & gRemoteCommand &"}!" _
								& "\\" & gTargetComputerName & namespace)
			Else
				Dim objSWbemLocator : Set objSWbemLocator = CreateObject("WbemScripting.SWbemLocator")
				Dim objSWbemServices : Set objSWbemServices = objSWbemLocator.ConnectServer(gTargetComputerName, namespace, gUsername, gPassword)

				'6 = pktPrivacy
				objSWbemServices.Security_.AuthenticationLevel = 6
				Set getWMIObject=objSWbemServices
			End If
		End Function

		' Adds a key-value pair to the gChangedSettings dictionary
		' If there isnt a key already just add the pair
		' If there is a key update it
		' Color the setting if it is being changed from the current value
		Sub addToChanges(key)
			Dim o
			For Each o In Document.getElementById(key).Options
				If o.Selected Then
					If(gChangedSettings.Exists(key)) Then
						gChangedSettings(key) = o.Text
						If(gCurrentSettings(key) = o.Text) Then
							gChangedSettings.remove(key)
							changeColor (key & "Text"), "black"
						Else
							changeColor (key & "Text"), "red"
						End If
					Else
						gChangedSettings.add key, o.Text
						changeColor (key & "Text"), "red"
					End If
					WriteToLogFile("Updating " & key & " to " & o.Text)
				End If
			Next
		End Sub

		'Clears out all the changed settings and reselects the current settings on the computer
		Sub ResetSub
			Dim key, o
			WriteToLogFile("Reverting all changes to the previously set values")
			For Each key in gChangedSettings
				gChangedSettings.Remove(key)
				If (InStr (key, "Boot Sequence") > 0 Or InStr (key, "BootSequence") > 0 Or key = "BootOrder") Then
					resetBootLists key, gCurrentSettings(key)
				ElseIf (InStr(key, "Alarm Time") > 0 Or InStr(key, "AlarmTime") > 0) Then
					resetAlarmTime key, gCurrentSettings(key)
				ElseIf(InStr(key, "Alarm Date") > 0 Or InStr(key, "AlarmDate") > 0) Then
					resetAlarmDate key, gCurrentSettings(key)
				Else
					For Each o in Document.getElementById(key).Options
						If (o.Text = gCurrentSettings(key)) Then
							o.selected = True
						End If
					Next
				End If
				changeColor(key & "Text"), "black"
			Next
		End Sub

		'Adds the newly created boot order to the changes dictionary
		'Made it a function so JavaScript can call it
		Function addToChangesBootList(idOfSelect)
			Dim value : value = generateBootList(idOfSelect)
			Dim key : key = extractKey(idOfSelect)
			If(gModifiedBootOrder = True) Then
				Dim excluded : excluded = generateBootList(key & "right")
				If Len(excluded) = 0 Then
					value = value & ";[Excluded from boot order]"
				Else
					value = value & ";[Excluded from boot order:" & excluded & "]"
				End If
			End If

			If(gChangedSettings.Exists(key)) Then
				gChangedSettings(key) = value
				If(gCurrentSettings(key) = value) Then
					gChangedSettings.remove(key)
					changeColor (key & "Text"), "black"
				Else
					changeColor (key & "Text"), "red"
				End If
			Else
				gChangedSettings.add key, value
				changeColor (key & "Text"), "red"
			End If
			WriteToLogFile("Modifying " & key & " to " & value)
		End Function
		
		'Adds the newly created date to the changes dictionary
		Function addDateToChanges(key)
			Dim braces : braces = Left(gCurrentSettings(key),1)
			Dim value : value = generateDate(key, braces)
			If(gChangedSettings.Exists(key)) Then
				gChangedSettings(key) = value
				If(gCurrentSettings(key) = value) Then
					gChangedSettings.remove(key)
					changeColor (key & "Text"), "black"
				Else
					changeColor (key & "Text"), "red"
				End If
			Else
				gChangedSettings.add key, value
				changeColor (key & "Text"), "red"
			End If
			WriteToLogFile("Modifying " & key & " to " & value)
		End Function
		
		'Adds the newly created time to the changes dictionary
		Function addTimeToChanges(key)
			Dim braces : braces = Left(gCurrentSettings(key),1)
			Dim value : value = generateTime(key, braces)
			If(gChangedSettings.Exists(key)) Then
				gChangedSettings(key) = value
				If(gCurrentSettings(key) = value) Then
					gChangedSettings.remove(key)
					changeColor (key & "Text"), "black"
				Else
					changeColor (key & "Text"), "red"
				End If
			Else
				gChangedSettings.add key, value
				changeColor (key & "Text"), "red"
			End If
			WriteToLogFile("Modifying " & key & " to " & value)
		End Function

		'---------------------------------------------------------
		'--------------------- HTML subs -------------------------
		'---------------------------------------------------------


		' Creates a dropdown menu for the setting based off the WMI queries
		' Also sets the selected value to the current setting on the target machine
		Function CreatePicker(key, value, objWMIService)
			Dim htmlForDropdown, values, val, parsedValue
			val = ""
			parsedValue = ""
			values = ""
			If (InStr(key, "Alarm Time") > 0 Or InStr(key, "AlarmTime") > 0) Then
				htmlForDropdown = createAlarmTime(key, value)
			ElseIf(InStr(key, "Alarm Date") > 0 Or InStr(key, "AlarmDate") > 0) Then
				htmlForDropdown = createAlarmDate(key, value)
			ElseIf(gIsALaptop = True) Then
				Dim selItems, objItem2, strSelection
				Set selItems = objWMIService.ExecQuery("Select * from Lenovo_GetBiosSelections")
				For Each objItem2 in selItems
						objItem2.GetBiosSelections key + ";", strSelection
				Next
				values = Split(strSelection, ",")

				If(key = "BootOrder") Then
					parsedValue = Split(value, ":")
					htmlForDropdown = createBootOptionChoice(key, parsedValue, value)
					htmlForDropdown = htmlForDropdown & "<td><select id='" & key & "right' size='4'>"
					For Each val in values
						If (InStr(value, val) = 0) Then
							htmlForDropdown = htmlForDropdown & "<option value='" & val &"'>" & val & "</option>"
						End If
					Next
					htmlForDropdown = htmlForDropdown & "</select></td></tr></table>"
				Else
					htmlForDropdown = "<select style='width:175px' id='" & key _
									& "' onChange='addToChanges(" & chr(34) & key & chr(34) & ")'>"

					For Each val in values
						htmlForDropdown = htmlForDropdown & "<option value='" & val & "'"
						If (StrComp(val,value) = 0) Then
							htmlForDropdown = htmlForDropdown & " selected"

						End If
						htmlForDropdown = htmlForDropdown & ">" & val & "</option>"
					Next
					htmlForDropdown = htmlForDropdown & "</select>"
				End If
			Else

				If (InStr (key, "Boot Sequence") > 0 Or InStr (key, "BootSequence") > 0) Then
					parsedValue = Split(value, ":")
					values = Split(gValueList, ":")
					htmlForDropdown = createBootOptionChoice(key, parsedValue, value)
					htmlForDropdown = htmlForDropdown & "<td><select id='" & key & "right' size='4'>"
					For Each val in values
						If (InStr(val, "Excluded") = 0) Then
							htmlForDropdown = htmlForDropdown & "<option value='" & val &"'>" & val & "</option>"
						End If
					Next
					htmlForDropdown = htmlForDropdown & "</select></td></tr></table>"
				Else
					values = Split(gValueList, ",")
					htmlForDropdown = "<select style='width:175px' id='" & key _
									& "' onChange='addToChanges(" & chr(34) & key & chr(34) & ")'>"

					For Each val in values
						htmlForDropdown = htmlForDropdown & "<option value='" & val & "'"
						If (StrComp(val,value) = 0) Then
							htmlForDropdown = htmlForDropdown & " selected"
						End If
						htmlForDropdown = htmlForDropdown & ">" & val & "</option>"
					Next
					htmlForDropdown = htmlForDropdown & "</select>"
				End If
			End If
			CreatePicker=htmlForDropdown
		End Function

		' Method to reuse the code of creating the boot order changers
		' Returns a bunch of HTML code
		Function createBootOptionChoice(key, currentSettings, value)
			Dim result : result = ""
			Dim val
			result = result & "<p align='center'>Current setting: " & value & "</p>"
			result = result & "<table width='100%'><thead  style='font-size:60%;'><th>Boot Order</th><th>&nbsp;</th><th>Options</th></thead><tr><td>"
			result = result & "<select id='" & key & "bootList' size='4' width='80px'>"
			For Each val in currentSettings
				result = result & "<option value='"& val &"'>" & val & "</option>"
			Next
			result = result & "</select></td>"
			result = result & "<td align='center' padding='8px'><input type='button' value='Up'  style='font-size:60%;width:80px' onclick='moveUp(" & chr(34) & key & "bootList"& chr(34) &")'><br>" _
											  & "<input type='button' value='Down' style='font-size:60%;width:80px' onclick='moveDown(" & chr(34) & key & "bootList"& chr(34) &")'><br>" _
											  & "<br><input  style='font-size:60%;' onclick='swapElement "& chr(34) & key & "right"& chr(34) &","& chr(34) & key & "bootList"& chr(34) &"' type='button' value='&nbsp;<<&nbsp;'>" _
											  & "&nbsp;&nbsp;<input  style='font-size:60%;' onclick='swapElement "& chr(34) & key & "bootList"& chr(34) &","& chr(34) & key & "right"& chr(34) &"' type='button' value='&nbsp;>>&nbsp;'></td>"
			createBootOptionChoice=result
		End Function
		
		Function createAlarmDate(key, value)
			Dim result : result = ""
			Dim i, j, k
			Dim values : values = Split(value, "/")
			Dim monthValue : monthValue = Right(values(0),2)
			Dim dayValue : dayValue = values(1)
			Dim yearValue : yearValue = Left(values(2),4)
			
			result = result & "<p align='center'>Current setting: " & value & "</p>"
			result = result & "<select onchange='addDateToChanges "& chr(34) & key & chr(34) &"' align='center' id='" & key & "MM'>"
			For i = 1 To 12
				If (CInt(monthValue) = i) Then
					If i < 10 Then
						result = result & "<option value='0" & i & "' selected >0" & i & "</option>"
					Else
						result = result & "<option value='" & i & "' selected >" & i & "</option>"
					End If
				Else
					If i < 10 Then
						result = result & "<option value='0" & i & "'>0" & i & "</option>"
					Else
						result = result & "<option value='" & i & "'>" & i & "</option>"
					End If
				End If
			Next
			
			result = result & "</select><select onchange='addDateToChanges "& chr(34) & key & chr(34) &"' align='center' id='" & key & "DD'>"
			For j = 1 To 31
				If (CInt(dayValue) = j) Then
					If j < 10 Then
						result = result & "<option value='0" & j & "' selected >0" & j & "</option>"
					Else
						result = result & "<option value='" & j & "' selected >" & j & "</option>"
					End If
				Else
					If j < 10 Then
						result = result & "<option value='0" & j & "'>0" & j & "</option>"
					Else
						result = result & "<option value='" & j & "'>" & j & "</option>"
					End If
				End If
			Next
			
			result = result & "</select><select onchange='addDateToChanges "& chr(34) & key & chr(34) &"' align='center' id='" & key & "YY'>"
			For k = 2000 To 2100
				If (CInt(yearValue) = k) Then
					result = result & "<option value='" & k & "' selected >" & k & "</option>"
				Else
					result = result & "<option value='" & k & "'>" & k & "</option>"
				End If
			Next
			
			result = result & "</select>"
			createAlarmDate=result
		End Function
		
		Function createAlarmTime(key, value)
			Dim result : result = ""
			Dim i, j, k
			Dim values : values = Split(value, ":")
			Dim hourValue : hourValue = Right(values(0),2)
			Dim minuteValue : minuteValue = values(1)
			Dim secondValue : secondValue = Left(values(2),2)
			result = result & "<p align='center'>Current setting: " & value & "</p>"
			result = result & "<select onchange='addTimeToChanges "& chr(34) & key & chr(34) &"' align='center' id='" & key & "HH'>"
			For i = 0 To 23
				If (CInt(hourValue) = i) Then
					If i < 10 Then
						result = result & "<option value='0" & i & "' selected >0" & i & "</option>"
					Else
						result = result & "<option value='" & i & "' selected >" & i & "</option>"
					End If
				Else
					If i < 10 Then
						result = result & "<option value='0" & i & "'>0" & i & "</option>"
					Else
						result = result & "<option value='" & i & "'>" & i & "</option>"
					End If
				End If
			Next
			
			result = result & "</select><select onchange='addTimeToChanges "& chr(34) & key & chr(34) &"' align='center' id='" & key & "MM'>"
			For j = 0 To 59
				If (CInt(minuteValue) = j) Then
					If j < 10 Then
						result = result & "<option value='0" & j & "' selected >0" & j & "</option>"
					Else
						result = result & "<option value='" & j & "' selected >" & j & "</option>"
					End If
				Else
					If j < 10 Then
						result = result & "<option value='0" & j & "'>0" & j & "</option>"
					Else
						result = result & "<option value='" & j & "'>" & j & "</option>"
					End If
				End If
			Next
			
			result = result & "</select><select onchange='addTimeToChanges "& chr(34) & key & chr(34) &"' align='center' id='" & key & "SS'>"
			For k = 0 To 59
				If (CInt(secondValue) = k) Then
					If k < 10 Then
						result = result & "<option value='0" & k & "' selected >0" & k & "</option>"
					Else
						result = result & "<option value='" & k & "' selected >" & k & "</option>"
					End If
				Else
					If k < 10 Then
						result = result & "<option value='0" & k & "'>0" & k & "</option>"
					Else
						result = result & "<option value='" & k & "'>" & k & "</option>"
					End If
				End If
			Next
			
			result = result & "</select>"
			createAlarmTime=result
		End Function
			

		' Display a secondary menu if the user says there is a supervisor password on the target machine
		' Creates a space for the password, encrypting key, encoding type and language
		Sub ShowPasswordInfoSub
			Dim passwordHTML : passwordHTML = ""
			If (supervisor.Checked = True) Then
				passwordHTML = passwordHTML & "<table id='passwordtable'><tr><td><label for='passEncode'>Encoding:</label>" _
											& "<select id='passEncode'><option value='ascii'>ascii</option>" _
											& "<option value='scancode'>scancode</option></select></td>" _
											& "<td><label for='passBox' " _
											& "title='Your supervisor password'>Enter password:</label>" _
											& "<input type='password' id='passBox'></td></tr>" _
											& "<tr><td><label for='passLang'>Language:</label>" _
											& "<select id='passLang'><option value='us'>us</option>" _
											& "<option value='fr'>fr</option>" _
											& "<option value='gr'>gr</option></select></td>" _
											& "<td><label for='passEncrypt' " _
											& "title='Used for exporting settings with supervisor password.'>Enter encrypting key:</label>" _
											& "<input type='textbox' id='passEncrypt' value=''></td></tr>" _
											& "<tr><td></td><td align='right'><input type='button' class='btn' value='Generate a key' name='random_key_button' onClick='generateRandomValue'</td></tr>" _ 
											& "<tr><td><input type='checkbox' id='changeSupervisor' value='Yes' onClick='showChangePasswordInfoSub' style='width:30px;height:30px;margin-right:10px;'>Change Supervisor password</td></tr></table>"
			Else
				passwordHTML = ""
				passwordChangeStuff.innerHTML = ""
			End If
			passwordStuff.innerHTML = passwordHTML
			
		End Sub
		
		' Display a secondary menu if the user says there is a supervisor password on the target machine
		' Creates a space for the password, encrypting key, encoding type and language
		Sub ShowChangePasswordInfoSub
			Dim passwordChangeHTML : passwordChangeHTML = ""
			If (changeSupervisor.Checked = True) Then
				passwordChangeHTML = passwordChangeHTML & "<table id='changepasswordtable'><tr>" _
											& "<td><label for='newPassBox' " _
											& "title='New password'>New password:</label>" _
											& "<input type='password' id='newPassBox'></td>" _
											& "<td><input type='button' class='btn' tabindex='-1' value='Change password' name='password_button' onClick='ChangePassword'></td></tr>" _
											& "<tr><td><label for='newPassBox' " _
											& "title='New password'>Confirm password:</label>" _
											& "<input type='password' id='confirmPassBox'></td>" _
											& "<td><input type='button' class='btn' value='Create password change file' name='password_button' onClick='CreatePasswordChangeFile'></td></tr></table>"
			Else
				passwordChangeHTML = ""
			End If
			passwordChangeStuff.innerHTML = passwordChangeHTML
		End Sub

		' Display a secondary menu if the user says there is a supervisor password on the target machine
		' Creates a space for the password, encrypting key, encoding type and language
		Sub ShowUserInfoSub
			Dim userHTML : userHTML = ""
			If (user.Checked = True) Then
				userHTML = userHTML & "<table id='usertable'><tr>" _
											& "<td><label for='username' title='Username you wish to connect with.'>Enter username:</label>" _
											& "<input type='textbox' id='uNameBox'></td></tr>" _
											& "<td><label for='uPassBox' title='The password for that username password'>Enter password:</label>" _
											& "<input type='password' id='uPassBox'></td></tr>" _
											& "<tr><td><label>Add <em>yourDomain\</em> if needed to the username</label></td></tr></table>"
			Else
				userHTML = ""
			End If
			userStuff.innerHTML = userHTML
		End Sub

		'---------------------------------------------------------
		'--------------------- Input subs ------------------------
		'---------------------------------------------------------

		' Restore the default settings for the targeted machine
		Sub SetDefaults
			Dim a : a = MsgBox("Are you sure you want to restore the default settings?",1,"Warning")
			If(a = 1) Then
				If(doValidationSave()) Then
					SetDefaultsCMD ""
					gPwd = ""
						
					msgbox "The default settings will be applied at next reboot."
					If (supervisor.Checked = True) Then
						passBox.value = ""
					End If
					TestSub
				End If
			End If
		End Sub
		
		' Restore the default settings for the targeted machine
		Sub SetDefaultsCMD (passKey)
			Dim colItems, strReturn, objItem
			
			If (passKey <> "") Then
				If(InStr(passKey, ",") > 0 Or gCanUseComplexPassword = True) Then
					gPwd = passKey
				Else
					gPwd = passKey & ",ascii,us"
				End If
			End If
			
			Dim objWMIService : Set objWMIService = getWMIObject("\root\wmi")
			Set colItems = objWMIService.ExecQuery("Select * from Lenovo_LoadDefaultSettings")

			If (gCanUseComplexPassword = False) Then
				strReturn = "error"
				For Each objItem in colItems
					ObjItem.LoadDefaultSettings gPwd & ";", strReturn
				Next

				If(strReturn = "Success") Then
					Set colItems = objWMIService.ExecQuery("Select * from Lenovo_SaveBiosSettings")

					strReturn = "error"
					For Each objItem in colItems
						ObjItem.SaveBiosSettings gPwd & ";", strReturn
					Next
					Set objWMIService = Nothing
				End If
				
				WriteToLogFile("Reverting settings to defaults: " & strReturn)
			Else
				strReturn = "error"
				For Each objItem in colItems
					ObjItem.LoadDefaultSettings ";", strReturn
				Next

				If(strReturn = "Success") Then
					Set colItems = objWMIService.ExecQuery("Select * from Lenovo_WmiOpcodeInterface")
					Dim strRequestAdmin : strRequestAdmin ="WmiOpcodePasswordAdmin:"+ gPwd +";"
					
					For Each objItem in colItems
						objItem.WmiOpcodeInterface strRequestAdmin, strReturn
					Next
					
					Set colItems = objWMIService.ExecQuery("Select * from Lenovo_SaveBiosSettings")
					strReturn = "error"
					For Each objItem in colItems
						ObjItem.SaveBiosSettings ";", strReturn
					Next
				End If
				
				WriteToLogFile("Reverting settings to defaults: " & strReturn)
			End If
		End Sub

		' Save the pending changes to the targeted machine
		Sub SaveChanges()
			If (doValidationSave) Then
				If(TestPassword) Then
					If(gCanUseComplexPassword = True) Then
						SaveChangesComplex
					Else
						SaveChangesSimple
					End If
				End If
			End If
		End Sub
		
				' Save the pending changes to the targeted machine
		Sub SaveChangesSimple()
			Dim colItems, objFSO, objLog, objItem, strRequest, resultString, strReturn, key
			resultString = ""

			Dim objWMIService : Set objWMIService = getWMIObject("\root\wmi")
			If(gChangedSettings.Count > 0) Then
				For Each key In gChangedSettings
					
					'If (InStr (key, "Boot Sequence") > 0 Or InStr (key, "BootSequence") > 0 Or key = "BootOrder") Then
					'	gChangedSettings(key) = VerifyBootOrder(key)
					'End If
					
					Set colItems = objWMIService.ExecQuery("Select * from Lenovo_SetBiosSetting")
					strRequest = key + "," + gChangedSettings(key)

					If(gPwd <> "") Then
						strRequest = strRequest + "," + gPwd
					End If

					strRequest = strRequest + ";"

					For Each objItem in colItems
						ObjItem.SetBiosSetting strRequest, strReturn
					Next
					
																		 
					If(strReturn = "Success") Then
						Set colItems = objWMIService.ExecQuery("Select * from Lenovo_SaveBiosSettings")
						strReturn = "error"
						For Each objItem in colItems
							ObjItem.SaveBiosSettings gPwd & ";", strReturn
						Next
						resultString = resultString & "Saving " & key & ": " & strReturn & vbCrLf
					Else
						gErrorLevel = 1
						resultString = resultString & "Setting " & key & " to " & gChangedSettings(key) & ": " & strReturn & vbCrLf
					End If
				Next
				
				gPwd = ""
				WriteToLogFile(resultString)
				
				If (gRefresh = True) Then
					msgbox resultString & vbCrLf & vbCrLf & "Any successful settings will be applied at next reboot."
					If (supervisor.Checked = True) Then
						passBox.value = ""
					End If
					TestSub
				End If
			ElseIf(gFirstRun = False) Then
				MsgBox "No changes found"
			End If
		End Sub
		
		' Save the pending changes to the targeted machine
		Sub SaveChangesComplex()
			Dim colItems, objFSO, objLog, objItem, strRequest, resultString, strReturn, key
			resultString = ""

			Dim objWMIService : Set objWMIService = getWMIObject("\root\wmi")
			If(gChangedSettings.Count > 0) Then
				For Each key In gChangedSettings
					
					'If (InStr (key, "Boot Sequence") > 0 Or InStr (key, "BootSequence") > 0 Or key = "BootOrder") Then
					'	gChangedSettings(key) = VerifyBootOrder(key)
					'End If
					
					Set colItems = objWMIService.ExecQuery("Select * from Lenovo_SetBiosSetting")
					strRequest = key + "," + gChangedSettings(key)

					strRequest = strRequest + ";"

					For Each objItem in colItems
						ObjItem.SetBiosSetting strRequest, strReturn
					Next
					
					If(strReturn = "Success") Then
						Set colItems = objWMIService.ExecQuery("Select * from Lenovo_WmiOpcodeInterface")
						Dim strRequestAdmin : strRequestAdmin ="WmiOpcodePasswordAdmin:"+ gPwd +";"
						
						For Each objItem in colItems
							objItem.WmiOpcodeInterface strRequestAdmin, strReturn
						Next
						
						Set colItems = objWMIService.ExecQuery("Select * from Lenovo_SaveBiosSettings")
						strReturn = "error"
						For Each objItem in colItems
							ObjItem.SaveBiosSettings ";", strReturn
						Next
						resultString = resultString & "Saving " & key & ": " & strReturn & vbCrLf
					Else
						gErrorLevel = 1
						resultString = resultString & "Setting " & key & " to " & gChangedSettings(key) & ": " & strReturn & vbCrLf
					End If
				Next
				
				gPwd = ""
				WriteToLogFile(resultString)
				
				If (gRefresh = True) Then
					msgbox resultString & vbCrLf & vbCrLf & "Any successful settings will be applied at next reboot."
					If (supervisor.Checked = True) Then
						passBox.value = ""
					End If
					TestSub
				End If
			ElseIf(gFirstRun = False) Then
				MsgBox "No changes found"
			End If
		End Sub

		Function VerifyBootOrder(key)
			Dim arrayOfOptions, arrayOfRequestedValue, values, requestedValue, possibleValue, counter
			Dim verifiedOptions
			If(gIsALaptop = True) Then
				Dim selItems, objItem2, strSelection
				Set selItems = objWMIService.ExecQuery("Select * from Lenovo_GetBiosSelections")
				For Each objItem2 in selItems
					objItem2.GetBiosSelections key + ";", strSelection
				Next
				values = Split(strSelection, ",")

				If(key = "BootOrder") Then
					arrayOfOptions = Split(values(1), ":")
				End If
				
				verifiedOptions = Array(UBound(arrayOfOptions) + 1)
				arrayOfRequestedValue = Split(gChangedSettings(key), ":")
				counter = 0
				For Each strValue in arrayOfRequestedValue
					For Each possibleValue in arrayOfOptions
						If (strValue = possibleValue) Then
							verifiedOptions(counter) = strValue
							counter = counter + 1
						End If
					Next
				Next
			End If
			VerifyBootOrder=Join(verifiedOptions, ":")
		End Function

		Function TestPassword()
			If(gCanUseComplexPassword = True) Then
				TestPassword=TestPasswordComplex
			Else
				TestPassword=TestPasswordSimple
			End If
		End Function

		Function TestPasswordSimple()
			Dim colItems, strReturn, objItem
			Dim objWMIService : Set objWMIService = getWMIObject("\root\wmi")
			Set colItems = objWMIService.ExecQuery("Select * from Lenovo_SaveBiosSettings")
			strReturn = "error"
			For Each objItem in colItems
				ObjItem.SaveBiosSettings gPwd & ";", strReturn
			Next
			
			If StrComp(strReturn,"Success") = 0 Then
				WriteToLogFile("Validated password")
				TestPasswordSimple=True
			Else
				WriteToLogFile("Password incorrect!")
				TestPasswordSimple = False
			End If
		End Function

		Function TestPasswordComplex()
			If(Len(gPwd) = 0) Then
				TestPasswordComplex = True
			Else			
				Dim colItems, strReturn, objItem
				Dim objWMIService : Set objWMIService = getWMIObject("\root\wmi")
				Set colItems = objWMIService.ExecQuery("Select * from Lenovo_SetBiosSetting")
				Dim strRequest : strRequest = gCurrentSettings.Keys()(0) + "," + gCurrentSettings.Items()(0)
				
				strRequest = strRequest + ";"
				WriteToLogFile(strRequest)
				
				For Each objItem in colItems
					ObjItem.SetBiosSetting strRequest, strReturn
				Next
				
				Set colItems = objWMIService.ExecQuery("Select * from Lenovo_WmiOpcodeInterface")
				'check if gPwd is empty
				Dim strRequestAdmin : strRequestAdmin ="WmiOpcodePasswordAdmin:"+ gPwd +";"
				WriteToLogFile(strRequestAdmin)
				For Each objItem in colItems
					objItem.WmiOpcodeInterface strRequestAdmin, strReturn
				Next
				
				If StrComp(strReturn,"Success") = 0 Then
					WriteToLogFile("Validated password")
					TestPasswordComplex = True
				Else
					WriteToLogFile(strReturn)
					TestPasswordComplex = False
				End If
			End If
		End Function		

		' Save the current and pending changes to a config file
		' If the supervisor box is checked then encrypt the password along with encoding and language
		Sub ExportChanges
			If(doValidationExport) Then
				Dim colItems, objFSO, outfile, objFile, key, excluded, value
				Set objFSO=CreateObject("Scripting.FileSystemObject")
				outFile = gCurrentDirectory & gTargetComputerModel & "Config.ini"
				Set objFile = objFSO.CreateTextFile(outFile,True)

				If (supervisor.Checked = True) Then
					objFile.Write EncryptValue(gPwd, passEncrypt.Value) & vbCrLf
					gPwd = ""
					passBox.value = ""

				End If

				For Each key In gCurrentSettings
					If(gChangedSettings.Exists(key)) Then
						If (InStr (key, "Boot Sequence") > 0 Or InStr (key, "BootSequence") > 0) Then
							If(gModifiedBootOrder = True) Then								
								'excluded = generateBootList(key & "right")
								'If Len(excluded) = 0 Then
								'	value = gChangedSettings(key) & ";[Excluded from boot order]"
								'Else
								'	value = gChangedSettings(key) & ";[Excluded from boot order:" & excluded & "]"
								'End If

								objFile.Write key & "," & gChangedSettings(key) & vbCrLf
							Else
								objFile.Write key & "," & gChangedSettings(key) & vbCrLf
							End If
						Else
							objFile.Write key & "," & gChangedSettings(key) & vbCrLf
						End If
					Else
						If (InStr (key, "Boot Sequence") > 0 Or InStr (key, "BootSequence") > 0) Then
							If(gModifiedBootOrder = True) Then								
								excluded = generateBootList(key & "right")
								If Len(excluded) = 0 Then
									value = gCurrentSettings(key) & ";[Excluded from boot order]"
								Else
									value = gCurrentSettings(key) & ";[Excluded from boot order:" & excluded & "]"
								End If

								objFile.Write key & "," & value & vbCrLf
							Else
								objFile.Write key & "," & gCurrentSettings(key) & vbCrLf
							End If
						ElseIf (InStr(key, "Alarm Time") > 0 OR InStr(key, "Alarm Date") > 0 Or InStr(key, "AlarmTime") > 0 OR InStr(key, "AlarmDate") > 0) Then
							Dim time : time = gCurrentSettings(key)
							If(Instr(time, "ShowOnly") > 0) Then
								Dim lastOpenBracket : lastOpenBracket = InStrRev(time, "[")
								objFile.Write key & "," & extractString(time, 0, lastOpenBracket-1) & vbCrLf
							Else
								objFile.Write key & "," & time & vbCrLf
							End If
						Else
							objFile.Write key & "," & gCurrentSettings(key) & vbCrLf
						End If
					End If
				Next
				objFile.Close

				Set objFile = Nothing
				WriteToLogFile("Exported the settings")
			End If
		End Sub

		' Save the current and pending changes to a config file
		' If the supervisor box is checked then encrypt the password along with encoding and language
		Sub CreatePasswordChangeFile
			If(doValidationPasswordChange) Then
				Dim colItems, objFSO, outfile, objFile, key, excluded, value
				Set objFSO=CreateObject("Scripting.FileSystemObject")
				outFile = gCurrentDirectory & gTargetComputerModel & "Password.ini"
				Set objFile = objFSO.CreateTextFile(outFile,True)

				If (supervisor.Checked = True) Then
					If Len(passBox.Value) = 0 Then
						objFile.Write EncryptValue(confirmPassBox.Value, passEncrypt.Value) & "|"
					Else
						objFile.Write EncryptValue(passBox.Value, passEncrypt.Value) & "|"
					End If
					objFile.Write EncryptValue(confirmPassBox.Value, passEncrypt.Value) & "|"
					objFile.Write EncryptValue((passEncode.Value & "," & passLang.Value), passEncrypt.Value)
				End If
				objFile.Close

				Set objFile = Nothing
				WriteToLogFile("Created a password change file")
			End If
		End Sub
		
		' Save the current and pending changes to a config file
		' If the supervisor box is checked then encrypt the password along with encoding and language
		Sub ChangePassword
			If(doValidationPasswordChange) Then
				Dim result
				
				result = vbYes
				If(Len(confirmPassBox.Value) < 1) Then
					result = MsgBox ("Are you sure you want to clear the supervisor password?", vbYesNo, "Clear supervisor password?")
				End If
				If(result = vbYes) Then
					If(gCanUseComplexPassword = True) Then
						ChangePasswordComplex
					Else
						ChangePasswordSimple
					End If
				End If
			End If
		End Sub
		
		Sub ChangePasswordSimple
			Dim colItems, objFSO, objItem, strRequest, strReturn, key
			strRequest = "pap," + passBox.Value + "," + confirmPassBox.Value + "," + (passEncode.Value & "," & passLang.Value) + ";"
			Dim objWMIService : Set objWMIService = getWMIObject("\root\wmi")
			Set colItems = objWMIService.ExecQuery("Select * from Lenovo_SetBiosPassword")

			strReturn = "error"
			For Each objItem in colItems
				ObjItem.SetBiosPassword strRequest, strReturn
			Next
			
			If(strReturn = "Success") Then
				WriteToLogFile(strReturn)
			Else
				WriteToLogFile(strReturn)
				gErrorLevel = 2
			End If
			MsgBox strReturn
		End Sub
		
		Sub ChangePasswordComplex
			Dim strReturn, strRequestType, strRequestCurrent, strRequestNew, strRequestAdmin, strRequestUpdate, colItems, objItem
			strRequestType ="WmiOpcodePasswordType:pap;"
			strRequestCurrent ="WmiOpcodePasswordCurrent01:"+ passBox.Value +";"
			strRequestNew ="WmiOpcodePasswordNew01:"+ confirmPassBox.Value +";"
			strRequestAdmin ="WmiOpcodePasswordAdmin:"+ passBox.Value +";"
			strRequestUpdate ="WmiOpcodePasswordSetUpdate;"
			Dim objWMIService : Set objWMIService = getWMIObject("\root\wmi")
			Set colItems = objWMIService.ExecQuery("Select * from Lenovo_WmiOpcodeInterface")

			strReturn = "error"
			For Each objItem in colItems
				objItem.WmiOpcodeInterface strRequestType, strReturn
			Next

			For Each objItem in colItems
				objItem.WmiOpcodeInterface strRequestCurrent, strReturn
			Next
			For Each objItem in colItems
				objItem.WmiOpcodeInterface strRequestNew, strReturn
			Next
		
			'If gIsALaptop = True Then
			'	strRequestUpdate = "WmiOpcodePasswordSetUpdate:" + passBox.Value + ";"
			'	For Each objItem in colItems
			'		objItem.WmiOpcodeInterface strRequestUpdate, strReturn
			'	Next
			'Else
			'	For Each objItem in colItems
			'		objItem.WmiOpcodeInterface strRequestAdmin, strReturn
			'	Next
				
				For Each objItem in colItems
					objItem.WmiOpcodeInterface strRequestUpdate, strReturn
				Next
			'End If
			
			If(strReturn = "Success") Then
				WriteToLogFile(strReturn)
			Else
				WriteToLogFile(strReturn)
				gErrorLevel = 2
			End If
			MsgBox strReturn
		End Sub
		
		
		' Save the current and pending changes to a config file
		' If the supervisor box is checked then encrypt the password along with encoding and language
		Sub generateRandomValue
			passEncrypt.value = makeid()
		End Sub
		
		
		'---------------------------------------------------------
		'--------------- Validation Functions --------------------
		'---------------------------------------------------------


		' Make sure the proper info is populated if a export is attempted
		Function doValidationExport()
			If (supervisor.Checked = True) Then
				If (Len(passBox.value) = 0) Then
					MsgBox "Please enter a supervisor password."
					passBox.focus
					doValidationExport = False
					Exit Function
				End If
				
				If (Len(passEncrypt.value) = 0) Then
					MsgBox "Please enter a key phrase."
					passEncrypt.focus
					doValidationExport = False
					Exit Function
				End If
				
				If Not isValidPassword(passEncrypt.value, gCanUseComplexPassword) Then
					MsgBox "The provided password is not valid for the system."
					passEncrypt.focus
					doValidationExport = False
					Exit Function
				Else
					doValidationExport = True
					If (gCanUseComplexPassword = False) Then
						gPwd = passBox.Value & "," & passEncode.Value & "," & passLang.Value
					Else
						gPwd = passBox.Value
					End If
				End If
			Else
				doValidationExport = True
			End If
		End Function
		
		' Make sure the proper info is populated if a export is attempted
		Function doValidationPasswordChange()
			Dim SystemDeployMode : SystemDeployMode = False
			If (supervisor.Checked = True) Then
				If (Len(passBox.value) = 0) Then
					Dim result : result = MsgBox ("Create password file for System Deploy Mode?", vbYesNo, "Confirm System Deploy Mode")

					Select Case result
					Case vbYes
						SystemDeployMode = True
					Case vbNo
						MsgBox "Please enter a supervisor password."
						passBox.focus
						doValidationPasswordChange = False
						Exit Function
					End Select
				End If
				
				If (Len(passEncrypt.value) = 0) Then
					MsgBox "Please enter a key phrase."
					passEncrypt.focus
					doValidationPasswordChange = False
				Else
					If Not isValidPassword(passEncrypt.value, gCanUseComplexPassword) Then
						MsgBox "Only alphanumeric characters are allowed in the key phrase."
						passEncrypt.focus
						doValidationPasswordChange = False
					ElseIf Not isValidPassword(newPassBox.value, gCanUseComplexPassword) Then
						MsgBox "The provided password is not valid for the system."
						newPassBox.focus
						doValidationPasswordChange = False
					ElseIf Not (confirmPassBox.value = newPassBox.value) Then
						MsgBox "New passwords do not match."
						newPassBox.focus
						doValidationPasswordChange = False
					Else
						doValidationPasswordChange = True
						If (gCanUseComplexPassword = False) Then
							gPwd = passBox.Value & "," & passEncode.Value & "," & passLang.Value
						Else
							gPwd = passBox.Value
						End If
					End If
				End If
			Else
				doValidationPasswordChange = True
			End If
		End Function

		' Make sure the proper info is populated if a save is attempted
		Function doValidationSave()
			If (supervisor.Checked = True) Then
				If (Len(passBox.value) = 0) Then
					MsgBox "Please enter a supervisor password."
					passBox.focus
					doValidationSave = False
				Else
					doValidationSave = True
					If (gCanUseComplexPassword = False) Then
						gPwd = passBox.Value & "," & passEncode.Value & "," & passLang.Value
					Else
						gPwd = passBox.Value
					End If
				End If
			Else
				doValidationSave = True
			End If
		End Function



		'---------------------------------------------------------
		'------------------- Targeting subs ----------------------
		'---------------------------------------------------------


		' Gathers a list of the all the references to the local machine
		' Info is stored in an array
		Sub getNetworkAddresses
			Dim intSize, objWMIService, colItems, objItem
			intSize = 1

			ReDim Preserve gNetworkArray(intSize)
			gNetworkArray(0) = "LOCALHOST"

			Set objWMIService = getWMIObject("\root\cimv2")
			Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_ComputerSystem")
			For Each objItem in colItems
				gNetworkArray(intSize) = objItem.Name
				intSize = intSize + 1
			Next

			Set colItems = objWMIService.ExecQuery("SELECT * FROM Win32_NetworkAdapterConfiguration Where IPEnabled=True")
			For Each objItem in colItems
				If Not IsNull(objItem.IPAddress(0)) Then
					ReDim Preserve gNetworkArray(intSize)
					gNetworkArray(intSize) = objItem.IPAddress(0)
					intSize = intSize + 1
				End If
			Next
		End Sub

		' Checks to see if the address being targeted is actually the local machine
		Function determineLocalMachine(computerAddress)
			Dim local : local = false
			Dim i
			For i = 0 to Ubound(gNetworkArray)
				If gNetworkArray(i) = UCase(computerAddress) then
					local = true
				End If
			Next
			determineLocalMachine=local
		End Function

		' Prompt the user for a hostname or ip that they want to access
		Sub RemoteSub
			Dim strMessage : strMessage = InputBox("Enter ip/hostname for computer you wish to remote access:", "Remote to computer")
			If strMessage <> "" Then
				If(Reachable(strMessage) = True) Then
					gTargetComputerName = strMessage
					gRemoteCommand = ",authenticationLevel=pktPrivacy"
					If(user.checked = True) Then
						gUsername = uNameBox.value
						gPassword = uPassBox.value
						uPassBox.value = ""
						uNameBox.value = ""
						user.checked = False
						ShowUserInfoSub
					Else
						gUsername = ""
						gPassword = ""
					End If
					gChangedSettings.RemoveAll
					gCurrentSettings.RemoveAll
					TestSub
				Else
					MsgBox "Host is unreachable"
				End If
			End If
		End Sub

		'Uses the WMI PingStatus object to determine if a host is reachable
		Function Reachable(strComputer)
			Dim wmiQuery, objWMIService, objPing, objStatus

			wmiQuery = "Select * From Win32_PingStatus Where Address = '" & strComputer & "'"

			Set objWMIService = getWMIObject("\root\cimv2")
			Set objPing = objWMIService.ExecQuery(wmiQuery)

			For Each objStatus in objPing
				If IsNull(objStatus.StatusCode) Or objStatus.Statuscode<>0 Then
					Reachable = False 'if computer is unreachable, return false
				Else
					Reachable = True 'if computer is reachable, return true
				End If
			Next
		End Function

		' Used by the 'Target local' button to bring the user back to the local machine settings.
		Sub LocalSub
			gTargetComputerName = "LOCALHOST"
			gRemoteCommand = ""
			gChangedSettings.RemoveAll
			gCurrentSettings.RemoveAll
			gUsername = ""
			gPassword = ""
			TestSub
		End Sub

		'---------------------------------------------------------
		'------------------ Commandline subs ---------------------
		'---------------------------------------------------------


		' Reads an exported configuration file
		' Compare this to the current settings on the computer and apply the difference
		Sub ParseFile(filename, passKey)
			Dim objFileToRead : Set objFileToRead=CreateObject("Scripting.FileSystemObject")
			Dim passwordChange : passwordChange = False
			If (InStr(filename, ":") = 0) Then
				filename = gCurrentDirectory & filename
			End If
			If (objFileToRead.FileExists(filename)) Then
				Dim encrypted, strLine, keyValue
				Set objFileToRead=CreateObject("Scripting.FileSystemObject").OpenTextFile(filename,1)
				If (gRefresh = False) Then
					encrypted = objFileToRead.ReadLine
					If(Instr(encrypted,"|") > 0) Then
						WriteToLogFile("Found password change file")
						Dim oldPass, newPass, encoding, parts
						parts = Split(encrypted, "|")
						oldPass = DecryptValue(parts(0), passKey)
						newPass = DecryptValue(parts(1), passKey)
						encoding = DecryptValue(parts(2), passKey)
						Dim colItems, objFSO, objItem, strRequest, strReturn, key
						strRequest = "pap," + oldPass + "," + newPass + "," + encoding + ";"
						Dim objWMIService : Set objWMIService = getWMIObject("\root\wmi")
						Set colItems = objWMIService.ExecQuery("Select * from Lenovo_SetBiosPassword")

						strReturn = "error"
						For Each objItem in colItems
							ObjItem.SetBiosPassword strRequest, strReturn
						Next
						If(strReturn = "Success") Then
							WriteToLogFile("Password change: " & strReturn)
						Else
							WriteToLogFile("Password change: " & strReturn)
							gErrorLevel = 2
						End If
						
						passwordChange = True
					ElseIf (passkey <> "" And InStr(encrypted, ",") > 0) Then
						If(InStr(passKey, ",") > 0 Or gCanUseComplexPassword = True) Then
							gPwd = passKey
						Else
							gPwd = passKey & ",ascii,us"
						End If
					ElseIf (passkey <> "") Then
						gPwd = DecryptValue(encrypted, passKey)
					End If
				End If
				objFileToRead.Close
				Set objFileToRead = Nothing

				if(passwordChange = False) Then
					WriteToLogFile("Parsing config file")
					Set objFileToRead=CreateObject("Scripting.FileSystemObject").OpenTextFile(filename,1)
					do while not objFileToRead.AtEndOfStream
						strLine = objFileToRead.ReadLine()
						If (InStr(strLine, ",") > 0) Then
							keyValue = Split(strLine, ",")
							If(gCurrentSettings.Exists(keyValue(0)) And gCurrentSettings(keyValue(0)) <> keyValue(1)) Then
								If (gChangedSettings.Exists(keyValue(0))) Then
									gChangedSettings(keyValue(0)) = keyValue(1)
								Else
									gChangedSettings.add Trim(keyValue(0)), Trim(keyValue(1))
								End If
							End If
						End If
					loop
					objFileToRead.Close
					Set objFileToRead = Nothing
					SaveChanges
				End If
			Else
				WriteToLogFile("Could not file the specified file.")
			End If
		End Sub

		' Used to make a single change
		' keyValue is of the form "key,value"
		Sub MakeSingleChange(setting, passKey)
			WriteToLogFile("Making a single change")
			If (passKey <> "") Then
				If(InStr(passKey, ",") > 0) Then
					gPwd = passKey
				Else
					gPwd = passKey & ",ascii,us"
				End If
			End If

			Dim keyValue : keyValue = Split(setting, ",")
			gChangedSettings.add keyValue(0), keyValue(1)
			SaveChanges 
		End Sub

		' Fill the current settings dictionary
		' This is used for the command line features
		Sub QuickFill
			Dim objWMIService, colItems, objItem, StrItem, StrValue
			Set objWMIService = getWMIObject("\root\wmi")
			Set colItems = objWMIService.ExecQuery("Select * from Lenovo_BiosSetting")
			Set objWMIService = Nothing
			For Each objItem in colItems
				If Len(objItem.CurrentSetting) > 0 Then
					StrItem = Left(ObjItem.CurrentSetting, InStr(ObjItem.CurrentSetting, ",") - 1)
					If(InStr(objItem.CurrentSetting, ";") > 0) Then
						StrValue = extractString(ObjItem.CurrentSetting, InStr(ObjItem.CurrentSetting, ","), InStr(ObjItem.CurrentSetting, ";") - 1)
					Else
						StrValue = Mid(ObjItem.CurrentSetting, InStr(ObjItem.CurrentSetting, ",") + 1, 256)
					End If
					If (Not(gCurrentSettings.Exists(StrItem))) Then
						gCurrentSettings.add StrItem, StrValue
					End If
				End If
			Next
			WriteToLogFile("Finished gathering settings.")
		End Sub

		'---------------------------------------------------------
		'------------------ Encryption subs ----------------------
		'---------------------------------------------------------

		' Decrypt some cipher text using a specified passphrase
		Function DecryptValue(cipherText, key)
			Dim result 
			Dim temp : temp = Tea.decrypt(cipherText, key)
			If (gCanUseComplexPassword = True) Then
				If(InStr(temp,",ascii,") > 0 Or InStr(temp,",scancode,") > 0) Then 
					result = Split(temp,",",2)(0)
				Else
					result = temp
				End If
			Else
				result = temp
			End If
			DecryptValue=result
		End Function

		' Encrypt a string using a specified passphrase
		Function EncryptValue(plainText, key)
			EncryptValue=Tea.encrypt(plainText, key)
		End Function

		'---------------------------------------------------------
		'-------------- Automatically called subs ----------------
		'---------------------------------------------------------

		'Prints the current error in a message box that the user can refer to
		Sub DisplayErrorInfo
			MsgBox 	"Error:      : " & Err & vbCrLf & "Error (hex) : &H" & Hex(Err) & vbCrLf & _
					"Source      : " & Err.Source & vbCrLf & "Description : " & Err.Description
			Err.Clear
		End Sub

		' Message box to warn user that there were unsaved changes
		Sub checkForPendingChanges
			If (gChangedSettings.Count <> 0 And gRefresh = True) Then
				MsgBox "There were pending changes which were not saved"
			End If
		End Sub

		' Dynamically set the window size based on the current resolution
		Sub SetWindowSize
			If (screen.availWidth > 2000) Then
				window.resizeTo screen.availWidth * .50, screen.availHeight * .85
			ElseIf (screen.availWidth > 1300) Then
				window.resizeTo screen.availWidth * .90, screen.availHeight * .90
			End If			
			
			window.moveTo 0, 0
		End Sub
		

		' Sub to run on the execution of the program.
		' Checks for command line parameters and processes them
		' Parameters are encased with quotes
		' file - A file with comma separated values to be applied to the system
		' config - A comma separated key-value pair to be applied to the system
		' pass/key - Either the supervisor password in the case of config or the keyphrase for encryption for the config file
		' help - Will display a help window
		' remote - Target a different computer using the command line options

		Sub Window_onLoad
			Dim passKey : passKey = ""
			Dim default : default = "false"
			Dim fileLocation : fileLocation = ""
			Dim configSetting : configSetting = ""
			Dim encrypted : encrypted = ""
			Dim arrCommands, breakdown, i
			Dim cmdSwitches : cmdSwitches = ""
			window.moveTo -2000, -2000

			' Parse the command line parameters
			' Split on quotes so read every other line
			' Every even index is a blank space
			' chr(34) = "
			TestElevation(objTBCHTA.commandLine)
			arrCommands = Split(objTBCHTA.commandLine, chr(34))
			gCurrentDirectory = extractString(arrCommands(1), 0, InStrRev(arrCommands(1), "\"))
			gTargetComputerModel = UpdateComputerModel
			gLogLocation = gCurrentDirectory
			gCanUseComplexPassword = ComplexPasswordClassExists										  
			
			For i = 3 to (Ubound(arrCommands) - 1) Step 2
				breakdown = Split(arrCommands(i), "=")
				Select Case LCase(breakdown(0))
					Case "pass"
						passKey = breakdown(1)
						cmdSwitches = cmdSwitches & "pass=**********" & VbCrLf
					Case "key"
						passKey = breakdown(1)
						cmdSwitches = cmdSwitches & "key=**********" & VbCrLf
					Case "file"
						fileLocation = breakdown(1)
						cmdSwitches = cmdSwitches & "fileLocation=" & fileLocation & VbCrLf
					Case "config"
						configSetting = breakdown(1)
						cmdSwitches = cmdSwitches & "config=" & configSetting & VbCrLf
					Case "log"
						gLogLocation = breakdown(1)
						cmdSwitches = cmdSwitches & "log=" & gLogLocation & VbCrLf
					Case "nolog"
						gNoLog = True
					Case "help"
						MsgBox displayRecentChanges
					Case "default"
						If( UBound(breakdown) > 0) Then
							default = LCase(breakdown(1))
						End If
					Case "remote"
						gTargetComputerName = breakdown(1)
						gRemoteCommand = ",authenticationLevel=pktPrivacy"
				End Select
			Next
			
			If (Right(gLogLocation,1) <> "\") Then
				gLogLocation = gLogLocation & "\"
			End If
			
			WriteToLogFile("-------------" & Now & "--------------")
			WriteToLogFile("BiosVersion: " & gBiosVersion)
			If(cmdSwitches <> "") Then
				WriteToLogFile(cmdSwitches)
			End If 
			
			If(fileLocation <> "") Then
				QuickFill
				ParseFile fileLocation, passKey
				closeHTA(gErrorLevel)
				' Window.close()
			ElseIf (configSetting <> "") Then
				QuickFill
				MakeSingleChange configSetting, passKey
				closeHTA(gErrorLevel)
				' Window.close()
			ElseIf(default = "true") Then
				QuickFill
				SetDefaultsCMD passKey
				closeHTA(gErrorLevel)
				' Window.close()
			Else
				SetWindowSize
				If(gSupervisorPassword = True) Then
					supervisor.click()
				End If
				TestSub
			End If
		End Sub
		
		Function displayRecentChanges
			Dim result
			result = "List of recent changes:" & VbCrLf
			
			result = result & VBTab & "1.22 - Added log file support" & VbCrLf
			result = result & VBTab & "1.20 - Fixed issue when remoting from a laptop to a desktop not displaying the settings properly" & VbCrLf
			result = result & VBTab & "1.17 - Bug fix on export of boot order" & VbCrLf
			result = result & VBTab & "1.16 - Ability to change the supervisor password" & VbCrLf
			result = result & VBTab & "1.15 - Future proofing and bugfix on Alarm Time and Date" & VbCrLf
			result = result & VBTab & "1.11 - Ability to set defaults via command line" & VbCrLf
			
			
			displayRecentChanges=result
		End Function
	</script>

	<script language="JavaScript" type="text/javascript">
		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
		/*  Block TEA (xxtea) Tiny Encryption Algorithm implementation in JavaScript                      */
		/*     (c) Chris Veness 2002-2012: www.movable-type.co.uk/tea-block.html                          */
		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
		/*  Algorithm: David Wheeler & Roger Needham, Cambridge University Computer Lab                   */
		/*             http://www.cl.cam.ac.uk/ftp/papers/djw-rmn/djw-rmn-tea.html (1994)                 */
		/*             http://www.cl.cam.ac.uk/ftp/users/djw3/xtea.ps (1997)                              */
		/*             http://www.cl.cam.ac.uk/ftp/users/djw3/xxtea.ps (1998)                             */
		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

		var Tea = {}; // Tea namespace
		/*
		 * encrypt text using Corrected Block TEA (xxtea) algorithm
		 *
		 * @param {string} plaintext String to be encrypted (multi-byte safe)
		 * @param {string} password  Password to be used for encryption (1st 16 chars)
		 * @returns {string} encrypted text
		 */
		Tea.encrypt = function(plaintext, password) {
			if (plaintext.length == 0) return (''); // nothing to encrypt
			// convert string to array of longs after converting any multi-byte chars to UTF-8
			var v = Tea.strToLongs(Utf8.encode(plaintext));
			if (v.length <= 1) v[1] = 0; // algorithm doesn't work for n<2 so fudge by adding a null
			// simply convert first 16 chars of password as key
			var k = Tea.strToLongs(Utf8.encode(password).slice(0, 16));
			var n = v.length;

			// ---- <TEA coding> ----
			var z = v[n - 1],
				y = v[0],
				delta = 0x9E3779B9;
			var mx, e, q = Math.floor(6 + 52 / n),
				sum = 0;

			while (q-- > 0) { // 6 + 52/n operations gives between 6 & 32 mixes on each word
				sum += delta;
				e = sum >>> 2 & 3;
				for (var p = 0; p < n; p++) {
					y = v[(p + 1) % n];
					mx = (z >>> 5 ^ y << 2) + (y >>> 3 ^ z << 4) ^ (sum ^ y) + (k[p & 3 ^ e] ^ z);
					z = v[p] += mx;
				}
			}

			// ---- </TEA> ----
			var ciphertext = Tea.longsToStr(v);

			return Base64.encode(ciphertext);
		}

		/*
		 * decrypt text using Corrected Block TEA (xxtea) algorithm
		 *
		 * @param {string} ciphertext String to be decrypted
		 * @param {string} password   Password to be used for decryption (1st 16 chars)
		 * @returns {string} decrypted text
		 */
		Tea.decrypt = function(ciphertext, password) {
			if (ciphertext.length == 0) return ('');
			var v = Tea.strToLongs(Base64.decode(ciphertext));
			var k = Tea.strToLongs(Utf8.encode(password).slice(0, 16));
			var n = v.length;

			// ---- <TEA decoding> ----
			var z = v[n - 1],
				y = v[0],
				delta = 0x9E3779B9;
			var mx, e, q = Math.floor(6 + 52 / n),
				sum = q * delta;

			while (sum != 0) {
				e = sum >>> 2 & 3;
				for (var p = n - 1; p >= 0; p--) {
					z = v[p > 0 ? p - 1 : n - 1];
					mx = (z >>> 5 ^ y << 2) + (y >>> 3 ^ z << 4) ^ (sum ^ y) + (k[p & 3 ^ e] ^ z);
					y = v[p] -= mx;
				}
				sum -= delta;
			}

			// ---- </TEA> ----
			var plaintext = Tea.longsToStr(v);

			// strip trailing null chars resulting from filling 4-char blocks:
			plaintext = plaintext.replace(/\0+$/, '');

			return Utf8.decode(plaintext);
		}

		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

		// supporting functions
		Tea.strToLongs = function(s) { // convert string to array of longs, each containing 4 chars
			// note chars must be within ISO-8859-1 (with Unicode code-point < 256) to fit 4/long
			var l = new Array(Math.ceil(s.length / 4));
			for (var i = 0; i < l.length; i++) {
				// note little-endian encoding - endianness is irrelevant as long as
				// it is the same in longsToStr()
				l[i] = s.charCodeAt(i * 4) + (s.charCodeAt(i * 4 + 1) << 8) + (s.charCodeAt(i * 4 + 2) << 16) + (s.charCodeAt(i * 4 + 3) << 24);
			}
			return l; // note running off the end of the string generates nulls since
		} // bitwise operators treat NaN as 0
		Tea.longsToStr = function(l) { // convert array of longs back to string
			var a = new Array(l.length);
			for (var i = 0; i < l.length; i++) {
				a[i] = String.fromCharCode(l[i] & 0xFF, l[i] >>> 8 & 0xFF, l[i] >>> 16 & 0xFF, l[i] >>> 24 & 0xFF);
			}
			return a.join(''); // use Array.join() rather than repeated string appends for efficiency in IE
		}


		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
		/*  Base64 class: Base 64 encoding / decoding (c) Chris Veness 2002-2012                          */
		/*    note: depends on Utf8 class                                                                 */
		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

		var Base64 = {}; // Base64 namespace
		Base64.code = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";

		/**
		 * Encode string into Base64, as defined by RFC 4648 [http://tools.ietf.org/html/rfc4648]
		 * (instance method extending String object). As per RFC 4648, no newlines are added.
		 *
		 * @param {String} str The string to be encoded as base-64
		 * @param {Boolean} [utf8encode=false] Flag to indicate whether str is Unicode string to be encoded
		 *   to UTF8 before conversion to base64; otherwise string is assumed to be 8-bit characters
		 * @returns {String} Base64-encoded string
		 */
		Base64.encode = function(str, utf8encode) { // http://tools.ietf.org/html/rfc4648
			utf8encode = (typeof utf8encode == 'undefined') ? false : utf8encode;
			var o1, o2, o3, bits, h1, h2, h3, h4, e = [],
				pad = '',
				c, plain, coded;
			var b64 = Base64.code;

			plain = utf8encode ? Utf8.encode(str) : str;

			c = plain.length % 3; // pad string to length of multiple of 3
			if (c > 0) {
				while (c++ < 3) {
					pad += '=';
					plain += '\0';
				}
			}
			// note: doing padding here saves us doing special-case packing for trailing 1 or 2 chars
			for (c = 0; c < plain.length; c += 3) { // pack three octets into four hexets
				o1 = plain.charCodeAt(c);
				o2 = plain.charCodeAt(c + 1);
				o3 = plain.charCodeAt(c + 2);

				bits = o1 << 16 | o2 << 8 | o3;

				h1 = bits >> 18 & 0x3f;
				h2 = bits >> 12 & 0x3f;
				h3 = bits >> 6 & 0x3f;
				h4 = bits & 0x3f;

				// use hextets to index into code string
				e[c / 3] = b64.charAt(h1) + b64.charAt(h2) + b64.charAt(h3) + b64.charAt(h4);
			}
			coded = e.join(''); // join() is far faster than repeated string concatenation in IE
			// replace 'A's from padded nulls with '='s
			coded = coded.slice(0, coded.length - pad.length) + pad;

			return coded;
		}

		/**
		 * Decode string from Base64, as defined by RFC 4648 [http://tools.ietf.org/html/rfc4648]
		 * (instance method extending String object). As per RFC 4648, newlines are not catered for.
		 *
		 * @param {String} str The string to be decoded from base-64
		 * @param {Boolean} [utf8decode=false] Flag to indicate whether str is Unicode string to be decoded
		 *   from UTF8 after conversion from base64
		 * @returns {String} decoded string
		 */
		Base64.decode = function(str, utf8decode) {
			utf8decode = (typeof utf8decode == 'undefined') ? false : utf8decode;
			var o1, o2, o3, h1, h2, h3, h4, bits, d = [],
				plain, coded;
			var b64 = Base64.code;

			coded = utf8decode ? Utf8.decode(str) : str;


			for (var c = 0; c < coded.length; c += 4) { // unpack four hexets into three octets
				h1 = b64.indexOf(coded.charAt(c));
				h2 = b64.indexOf(coded.charAt(c + 1));
				h3 = b64.indexOf(coded.charAt(c + 2));
				h4 = b64.indexOf(coded.charAt(c + 3));

				bits = h1 << 18 | h2 << 12 | h3 << 6 | h4;

				o1 = bits >>> 16 & 0xff;
				o2 = bits >>> 8 & 0xff;
				o3 = bits & 0xff;

				d[c / 4] = String.fromCharCode(o1, o2, o3);
				// check for padding
				if (h4 == 0x40) d[c / 4] = String.fromCharCode(o1, o2);
				if (h3 == 0x40) d[c / 4] = String.fromCharCode(o1);
			}
			plain = d.join(''); // join() is far faster than repeated string concatenation in IE
			return utf8decode ? Utf8.decode(plain) : plain;
		}


		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
		/*  Utf8 class: encode / decode between multi-byte Unicode characters and UTF-8 multiple          */
		/*              single-byte character encoding (c) Chris Veness 2002-2012                         */
		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */

		var Utf8 = {}; // Utf8 namespace
		/**
		 * Encode multi-byte Unicode string into utf-8 multiple single-byte characters
		 * (BMP / basic multilingual plane only)
		 *
		 * Chars in range U+0080 - U+07FF are encoded in 2 chars, U+0800 - U+FFFF in 3 chars
		 *
		 * @param {String} strUni Unicode string to be encoded as UTF-8
		 * @returns {String} encoded string
		 */
		Utf8.encode = function(strUni) {
			// use regular expressions & String.replace callback function for better efficiency
			// than procedural approaches
			var strUtf = strUni.replace(/[\u0080-\u07ff]/g, // U+0080 - U+07FF => 2 bytes 110yyyyy, 10zzzzzz


			function(c) {
				var cc = c.charCodeAt(0);
				return String.fromCharCode(0xc0 | cc >> 6, 0x80 | cc & 0x3f);
			});
			strUtf = strUtf.replace(/[\u0800-\uffff]/g, // U+0800 - U+FFFF => 3 bytes 1110xxxx, 10yyyyyy, 10zzzzzz


			function(c) {
				var cc = c.charCodeAt(0);
				return String.fromCharCode(0xe0 | cc >> 12, 0x80 | cc >> 6 & 0x3F, 0x80 | cc & 0x3f);
			});
			return strUtf;
		}

		/**
		 * Decode utf-8 encoded string back into multi-byte Unicode characters
		 *
		 * @param {String} strUtf UTF-8 string to be decoded back to Unicode
		 * @returns {String} decoded string
		 */
		Utf8.decode = function(strUtf) {
			// note: decode 3-byte chars first as decoded 2-byte strings could appear to be 3-byte char!
			var strUni = strUtf.replace(/[\u00e0-\u00ef][\u0080-\u00bf][\u0080-\u00bf]/g, // 3-byte chars


			function(c) { // (note parentheses for precedence)
				var cc = ((c.charCodeAt(0) & 0x0f) << 12) | ((c.charCodeAt(1) & 0x3f) << 6) | (c.charCodeAt(2) & 0x3f);
				return String.fromCharCode(cc);
			});
			strUni = strUni.replace(/[\u00c0-\u00df][\u0080-\u00bf]/g, // 2-byte chars


			function(c) { // (note parentheses for precedence)
				var cc = (c.charCodeAt(0) & 0x1f) << 6 | c.charCodeAt(1) & 0x3f;
				return String.fromCharCode(cc);
			});
			return strUni;
		}

		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
		/* - - - - - - - - - - - - - - - - - - - -Utility Functions- - - - - - - - - - - - - - - - - - -  */
		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
		
		/**
		 * Resizes the program appropriate to the current screen resolution
		 */
		function resetTextSize()
		{
			if(screen.width > 2000) 
			{
				document.getElementById("main").style.fontSize = "44px";
			}//end if
			else if(screen.width < 1440)
			{
				document.getElementById("main").style.fontSize = "8px";
				//alert(document.getElementById("main").style.fontSize);
			}//end else if
		}//end resetTextSize
		
		/**
		 * Some keys have < and > in the name.
		 * These need to be replaced before it can be displayed properly in HTML
		 *
		 * @param {String} str The name of the option.
		 * @returns {String} A modified version of the string with HTMl character codes embedded.
		 */
		function replaceSymbols(str)
		{
			return str.replace("<", "&lt;").replace(">", "&gt;");
		}//end replaceSymbols

		/**
		 * Validates that the provided string cantains only alphanumeric characters.
		 *
		 * @param {String} str The string to be validated
		 * @returns {boolean} True if valid, otherwise false
		 */
		function isAlphaNumeric(str)
		{
			var code, i, len;

			for (i = 0, len = str.length; i < len; i++)
			{
				code = str.charCodeAt(i);
				if (!(code > 47 && code < 58) && // (0-9)
					!(code > 64 && code < 91) && // (A-Z)
					!(code > 96 && code < 123))  // (a-z)
					return false;
			}//end for
			return true;
		}//end isAlphaNumeric
		
		/**
		 * Validates that the provided string cantains only alphanumeric characters.
		 *
		 * @param {String} str The string to be validated
		 * @returns {boolean} True if valid, otherwise false
		 */
		function isValidPassword(str, isStrong)
		{
			var code, i, len;
			if(isStrong == true)
			{
				for (i = 0, len = str.length; i < len; i++)
				{
					code = str.charCodeAt(i);
					if (!(code > 31 && code < 127))  // (a-zA-Z0-9 Space ! " # $ % & '( ) * + , - . / : ; < = > ? @ [ \ ] ^ _ ` { | } ~)
						return false;
				}//end for
				return true;
			}
			else
			{
				for (i = 0, len = str.length; i < len; i++)
				{
					code = str.charCodeAt(i);
					if (!(code > 47 && code < 58) && // (0-9)
						!(code > 64 && code < 91) && // (A-Z)
						!(code > 96 && code < 123))  // (a-z)
						return false;
				}//end for
				return true;
			}
		}//end isValidPassword

		/**
		 * Supplies the user with a randomly generated 16 character string
		 *
		 * @returns {String} 16 character encrypting key
		 */
		function makeid()
		{
			var text = "";
			var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

			for( var i=0; i < 16; i++ )
				text += possible.charAt(Math.floor(Math.random() * possible.length));

			return text;
		}//end makeid

		/**
		 * Changes the color of a specified element
		 *
		 * @param {String} id The string id of the element to be changed
		 * @param {String} color The string representation of a color
		 */
		function changeColor(id, color)
		{
			document.getElementById(id).style.color = color;
		}//end changeColor

		/**
		 * Turns a button on for use
		 *
		 * @param {String} id The string id of the button to be enabled
		 */
		function toggleButtonOn(id)
		{
			document.getElementById(id).disabled = false;
		}//end toggleButtonOn

		/**
		 * Turns a button off
		 *
		 * @param {String} id The string id of the button to be disabled
		 */
		function toggleButtonOff(id)
		{
			document.getElementById(id).disabled = true;
		}//end toggleButtonOff

		/**
		 * VBScript lacks a substring method
		 * This makes parsing much easier
		 *
		 * @param {String} str The string which a section is to be extracted from
		 * @param {String} start The beginning index
		 * @param {String} end The end index
		 * @returns {String} The substring of the original string
		 */
		function extractString (str, start, end)
		{
			return str.substring(start, end);
		}//end extractString
		
		/**
		 * Get the key of the boot option from the select id
		 * "bootList" is cut off
		 *
		 * @param {String} selectId The id of the select
		 */
		function extractKey (selectId)
		{
			return selectId.slice(0,-8);
		}//end extractKey

		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
		/* - - - - - - - - - - - - - - - - - - - BootList Functions  - - - - - - - - - - - - - - - - - -  */
		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
		
		
		/**
		 * Swaps elements from two different select lists
		 * Boot list is not allowed to be emptied
		 *
		 * @param {String} fromList The list the object is coming from
		 * @param {String} toList The list the object is moving to
		 */
		function swapElement(fromList,toList)
		{
			var selectOptions = document.getElementById(fromList);
			for (var i = 0; i < selectOptions.length; i++)
			{
				var opt = selectOptions[i];
				if (opt.selected && ((selectOptions.length > 1 && fromList.indexOf("bootList") > -1) || fromList.indexOf("right") > -1))
				{
					document.getElementById(fromList).removeChild(opt);
					document.getElementById(toList).appendChild(opt);
					i--;
				}//end if
			}//end for
			//figure out which is bootlist
			if(~fromList.indexOf("bootList"))
				addToChangesBootList(fromList);
			else
				addToChangesBootList(toList);
		}//end swapElement

		/**
		 * Moves the selected item up in the boot list
		 *
		 * @param {String} selectId The id of the select being modified
		 */
		function moveUp(selectId)
		{
			var selectList = document.getElementById(selectId);
			var selectOptions = selectList.getElementsByTagName('option');
			for (var i = 1; i < selectOptions.length; i++)
			{
				var opt = selectOptions[i];
				if (opt.selected)
				{
					selectList.removeChild(opt);
					selectList.insertBefore(opt, selectOptions[i - 1]);
				}//end if
			}//end for
			addToChangesBootList(selectId);
		}//end moveUp

		/**
		 * Moves the selected item down in the boot list
		 *
		 * @param {String} selectId The id of the select being modified
		 */
		function moveDown(selectId) {
			var selectList = document.getElementById(selectId);
			var selectOptions = selectList.getElementsByTagName('option');
			for (var i = selectOptions.length - 2; i >= 0; i--)
			{
				var opt = selectOptions[i];
				if (opt.selected)
				{
				   var nextOpt = selectOptions[i + 1];
				   opt = selectList.removeChild(opt);
				   nextOpt = selectList.replaceChild(opt, nextOpt);
				   selectList.insertBefore(nextOpt, opt);
				}//end if
			}//end for
			addToChangesBootList(selectId);
		}//end moveDown

		/**
		 * Function to create the colon separated string needed for the boot order key
		 *
		 * @param {String} id The id of the select element that needs to be converted
		 * @returns {String} The colon separated value
		 */
		function generateBootList(id)
		{
			var selectList = document.getElementById(id);
			var selectOptions = selectList.getElementsByTagName('option');
			var listString = "";
			for (var i = 0; i < selectOptions.length; i++)
			{
				listString += selectOptions[i].value;
				if(i < selectOptions.length - 1)
					listString += ":";
			}//end for
			return listString;
		}//end generateBootList
		
		/**
		 * Function to reset the boot list options to the orignal state
		 *
		 * @param {String} keyId The key of the option that needs to be reset
		 * @param {String} currentSettingForKey The current setting string for that key
		 */
		function resetBootLists(keyId, currentSettingForKey)
		{
			var bootSelectList = document.getElementById(keyId + "bootList");
			var excludeSelectList = document.getElementById(keyId + "right");
			var optionsForBootSelect = bootSelectList.getElementsByTagName('option');
			var optionsForExcludeSelect = excludeSelectList.getElementsByTagName('option');

			var allOptions = [];
			for(var i = 0; i < optionsForBootSelect.length; i++)
				allOptions.push(optionsForBootSelect[i]);

			for(var i = 0; i < optionsForExcludeSelect.length; i++)
				allOptions.push(optionsForExcludeSelect[i]);


			bootSelectList.InnerHTML = "";
			excludeSelectList.InnerHTML = "";

			var splitSettings = currentSettingForKey.split(":");
			for(var i = 0; i < splitSettings.length; i++)
			{
				var settingName = splitSettings[i];
				for(var j = 0; j < allOptions.length; j++)
				{
					if(allOptions[j].value == settingName)
					{
						bootSelectList.appendChild(allOptions[j]);
						allOptions.splice(j, 1);
					}//end if
				}//end for
			}//end for

			for(var i = 0; i < allOptions.length; i++)
				excludeSelectList.appendChild(allOptions[i]);
		}//end resetBootLists

		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
		/* - - - - - - - - - - - - - - - - - - - - Alarm Functions - - - - - - - - - - - - - - - - - - -  */
		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
		
		/**
		 * Function to create the forward slash seperated string needed for the date
		 *
		 * @param {String} key The key name of the setting that needs to be converted
		 * @returns {String} The forward slash separated value
		 */
		function generateDate(key, braces)
		{
			var daySelect = document.getElementById(key + "DD");
			var monthSelect = document.getElementById(key + "MM");
			var yearSelect = document.getElementById(key + "YY");
			
			var day = daySelect.options[daySelect.selectedIndex].value;
			var month = monthSelect.options[monthSelect.selectedIndex].value;
			var year = yearSelect.options[yearSelect.selectedIndex].value;
			
			var valid = checkDate(month, day, year);
			
			if(valid > -1)
			{
				daySelect.selectedIndex = valid - 1;
				day = daySelect.options[daySelect.selectedIndex].value;
			}
			if(isAlphaNumeric(braces))
				return month + "/" + day + "/" + year;
			else
				return "[" + month + "/" + day + "/" + year + "]";
		}//end generateDate
		
		/**
		 * Function to create the colon separated string needed for the alarm time settings
		 *
		 * @param {String} key The key name of the setting that needs to be converted
		 * @returns {String} The colon separated value
		 */
		function generateTime(key, braces)
		{
			var hourSelect = document.getElementById(key + "HH");
			var minSelect = document.getElementById(key + "MM");
			var secondSelect = document.getElementById(key + "SS");
			
			var hour = hourSelect.options[hourSelect.selectedIndex].value;
			var min = minSelect.options[minSelect.selectedIndex].value;
			var second = secondSelect.options[secondSelect.selectedIndex].value;
			
			if(isAlphaNumeric(braces))
				return hour + ":" + min + ":" + second;
			else
				return "[" + hour + ":" + min + ":" + second + "]";
		}//end generateTime

		/**
		 * Function to reset the alarm time to the orignal state
		 *
		 * @param {String} key The key of the option that needs to be reset
		 * @param {String} value The original setting string for that key
		 */
		function resetAlarmTime(key, value)
		{
			var hourSelect = document.getElementById(key + "HH");
			var minSelect = document.getElementById(key + "MM");
			var secondSelect = document.getElementById(key + "SS");
			
			var originalValues = value.split(":");
			var originalMinute = originalValues[1];
			var originalHour = originalValues[0].slice(-2);
			var originalSecond = originalValues[2].slice(0, 2);
			
			hourSelect.value = originalHour;
			minSelect.value = originalMinute;
			secondSelect.value = originalSecond;
		}//end resetAlarmTime
		
		/**
		 * Function to reset the alarm date to the orignal state
		 *
		 * @param {String} key The key of the option that needs to be reset
		 * @param {String} value The original setting string for that key
		 */
		function resetAlarmDate(key, value)
		{
			var daySelect = document.getElementById(key + "DD");
			var monthSelect = document.getElementById(key + "MM");
			var yearSelect = document.getElementById(key + "YY");
			
			var originalValues = value.split("/");
			var originalDay = originalValues[1];
			var originalMonth = originalValues[0].slice(-2);
			var originalYear = originalValues[2].slice(0, 4);
			
			daySelect.value = originalDay;
			monthSelect.value = originalMonth;
			yearSelect.value = originalYear;
		}//end resetAlarmDate
		
		// Validates that the input string is a valid date formatted as "mm/dd/yyyy"
		function checkDate(month, day, year)
		{
			var monthLength = [ 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 ];

			// Adjust for leap years
			if(year % 400 == 0 || (year % 100 != 0 && year % 4 == 0))
				monthLength[1] = 29;

			// Check the range of the day
			if(day <= monthLength[month - 1])
				return -1;
			return monthLength[month - 1];
		};
		
		function closeWithErrorlevel(errorlevel){
                var colProcesses = GetObject('winmgmts:{impersonationLevel=impersonate}!\\\\.\\root\\cimv2').ExecQuery('Select * from Win32_Process Where Name = \'mshta.exe\'');
                var myPath = (''+location.pathname).toLowerCase();
                var enumProcesses = new Enumerator(colProcesses);
                for ( var process = null ; !enumProcesses.atEnd() ; enumProcesses.moveNext() ) {
                    process = enumProcesses.item();
                    if ( (''+process.CommandLine).toLowerCase().indexOf(myPath) > 0 ){
                        process.Terminate(errorlevel);
                    }
                }
            }

            function closeHTA(value){
                // test close of window. Use default value
                if (typeof value === 'undefined') value = 0; 
                try { closeWithErrorlevel(value) } catch (e) {};
            }
		
		/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
		
	</script>
	<body id='mainbody' onresize='resetTextSize' onbeforeunload='checkForPendingChanges'>
		<div id="titlebar" class="titlebar">
<!--
			<div class="logobox" onclick="location.href='https://thinkdeploy.blogspot.com'">
				<div class="lenovo">Lenovo</div><div class="cdrt">Commercial Deployment Readiness Team</div>
			</div>
			<div id="title">Think BIOS Configurator</div>
-->			
			<table width='97%'>
				<tr>
					<td width='50%'>
						<div id="title">Think BIOS Config Tool v1.41</div> <!--UPDATE ME WITH EACH NEW VERSION -->
					</td>
					<td style="align:right;">
						<div class="logobox" onclick="location.href='https://thinkdeploy.blogspot.com'">
							<div class="lenovo">Lenovo</div><div class="cdrt">Commercial Deployment<br/>Readiness Team</div>
						</div>
					</td>
				</tr>
			</table>
		</div>
		<div id="fileActions" class="fileactions">
			<span class="sections"><strong>File Actions:<strong></span>
			<table width="97%" id="file_actions" cellpadding="20px">
				<tr>
					<td width="50%">
						<p>
							Select a previously created .ini file of settings
						</p>
						<input name="file" class="file" type="file" size="50" onChange="CheckFile"/><br><br>
						<input type="button" class="btn" id="configButton" value="Apply config file" name="file_button" onClick="ApplyFile" disabled="true">
					</td>

					<td style="border-left:solid 1px #d3d3d3;">
						<p>Create an .ini file containing the current settings of the target machine in the working directory.</p>
						<input type="button" class="btn" value="Export Settings" name="export_button" onClick="ExportChanges"> <br>
						<br>
					</td>
				</tr>
			</table>
		</div>
		<div id="security">
			<span class="sections"><strong>Security Actions:</strong></span>
			<span id="isThereAPassword"></span>
			<table width="97%" id="security_actions" cellpadding="20px">
			<tr>
				<td width="48%">
					<input type="checkbox" id="supervisor" value="Yes" onClick="showPasswordInfoSub" style="width:30px;height:30px;margin-right:10px;">Supervisor password set on the target machine
					<div id="passwordStuff" class="passwordstuff"></div>
					<div id="passwordChangeStuff" class="passwordChangeStuff"></div>
				</td>
				<td width="50%" style="border-left:solid 1px #d3d3d3;">
					<input type="checkbox" id="user" value="Yes" onClick="ShowUserInfoSub" style="width:30px;height:30px;margin-right:10px;">Use different credentials to connect to target machine
					<div id="userStuff" class="passwordstuff"></div>
				</td>
			</tr>
			</table>
		</div>
		<div id="targeting_div">
			<span class="sections"><strong>Targeting:</strong></span><br><br>
			<input type="button" class="btn" id="localButton" value="Target Local" name="local_button" onClick="LocalSub">
			<input type="button" class="btn" id="remoteButton" value="Target Remote" name="remote_button" onClick="RemoteSub">
			<br><br>
		</div>
		<div id="data_title">
			<br>
			<table id="targeted_settings" style="width:100%" cellpadding="14px">
			<tr>
				<td><center><span id="targeting"></span></center></td>
			</tr>
			<tr>
				<td>
					<center>
						<input type="button" class="btn" id="saveButton" value="Save Changed Settings" name="save_button" onClick="SaveChanges">
						<input type="button" class="btn" value="Restore BIOS Defaults" name="default_button" onClick="SetDefaults">
						<input type="button" class="btn" id="resetButton" value="Reset to Current Settings" name="reset_button" onClick="ResetSub">
					</center>
				</td>
			</tr>
			<tr>
				<td>
					<div id="dataArea" align="center" style="overflow:scroll">Loading data...</div>
				</td>
			</tr>
			</table>
		</div>
	</body>
</html>
'@


$LenSettings = @'
MKMQRdVPqqY=
WakeOnLANDock,Enable
IPv4NetworkStack,Enable
IPv6NetworkStack,Enable
UefiPxeBootPriority,IPv4First
MACAddressPassThrough,Enable
AlwaysOnUSB,Enable
TrackPoint,Enable
TouchPad,Enable
FnCtrlKeySwap,Disable
FnSticky,Disable
FnKeyAsPrimary,Disable
BootDisplayDevice,LCD
TotalGraphicsMemory,256MB
BootTimeExtension,Disable
SpeedStep,Enable
AdaptiveThermalManagementAC,MaximizePerformance
AdaptiveThermalManagementBattery,Balanced
CPUPowerManagement,Enable
OnByAcAttach,Disable
PasswordBeep,Disable
KeyboardBeep,Enable
HyperThreadingTechnology,Enable
AMTControl,Disable
USBKeyProvisioning,Disable
SystemManagementPasswordControl,Disable
PowerOnPasswordControl,Disable
HardDiskPasswordControl,Disable
BIOSSetupConfigurations,Disable
BlockSIDAuthentication,Enable
LockBIOSSetting,Disable
MinimumPasswordLength,Disable
BIOSPasswordAtUnattendedBoot,Enable
BIOSPasswordAtReboot,Disable
BIOSPasswordAtBootDeviceList,Disable
PasswordCountExceededError,Enable
FingerprintPredesktopAuthentication,Enable
FingerprintSecurityMode,Normal
FingerprintPasswordAuthentication,Enable
FingerprintSingleTouchAuthentication,Enable
SecurityChip,Enable
TXTFeature,Enable
PhysicalPresenceForTpmClear,Enable
BIOSUpdateByEndUsers,Enable
SecureRollBackPrevention,Enable
WindowsUEFIFirmwareUpdate,Enable
DataExecutionPrevention,Enable
VirtualizationTechnology,Enable
VTdFeature,Enable
EnhancedWindowsBiometricSecurity,Enable
WirelessLANAccess,Enable
WirelessWANAccess,Enable
BluetoothAccess,Enable
USBPortAccess,Enable
IntegratedCameraAccess,Enable
IntegratedAudioAccess,Enable
MicrophoneAccess,Enable
FingerprintReaderAccess,Enable
ThunderboltAccess,Enable
NfcAccess,Enable
BottomCoverTamperDetected,Disable
AbsolutePersistenceModuleActivation,Disable
SecureBoot,Enable
Allow3rdPartyUEFICA,Disable
KernelDMAProtection,Enable
TotalMemoryEncryption,Disable
ThinkShieldsecurewipe,Enable
ThinkShieldPasswordlessPowerOnAuthentication,Enable
BootMode,Quick
StartupOptionKeys,Enable
BootDeviceListF12Option,Enable
BootOrder,USBCD:USBFDD:NVMe0:USBHDD:PXEBOOT:LENOVOCLOUD:ON-PREMISE
NetworkBoot,PXEBOOT
BootOrderLock,Disable
WiFiNetworkBoot,Disable
LenovoCloudServices,Enable
ChargeInBatteryMode,Disable
StrongPassword,Disable
KeyboardLayout,English_UK
PCIeTunneling,Enable
WakeUponAlarm,Disable
AlarmTime,00:00:00
AlarmDate,01/01/2023
AlarmDayofWeek,Sunday
UserDefinedAlarmSunday,Disable
UserDefinedAlarmMonday,Disable
UserDefinedAlarmTuesday,Disable
UserDefinedAlarmWednesday,Disable
UserDefinedAlarmThursday,Disable
UserDefinedAlarmFriday,Disable
UserDefinedAlarmSaturday,Disable
UserDefinedAlarmTime,00:00:00
ePrivacyLock,Disable
ReinstallWindowsFromCloud,Disable
'@



$response = new-item x:\temp -itemtype directory -force

$code | out-file "x:\temp\ThinkBiosConfig.hta" -force -encoding ascii
$lensettings | out-file "x:\temp\LenBiosSettings.ini" -force -encoding ascii