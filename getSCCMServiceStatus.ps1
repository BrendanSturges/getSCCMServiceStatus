function Get-FileName($initialDirectory){   
	[System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
	$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
	$OpenFileDialog.initialDirectory = $initialDirectory
	$OpenFileDialog.filter = "All files (*.*)| *.*"
	$OpenFileDialog.ShowDialog() | Out-Null
	$OpenFileDialog.filename
}

function Save-File([string] $initialDirectory ) {
    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null

    $OpenFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $OpenFileDialog.initialDirectory = $initialDirectory
    $OpenFileDialog.filter = "All files (*.*)| *.*"
    $OpenFileDialog.ShowDialog() |  Out-Null
	
	$nameWithExtension = "$($OpenFileDialog.filename).csv"
	return $nameWithExtension
}

#Open a file dialog window to get the source file
$serverList = Get-Content -Path (Get-FileName)

#open a file dialog window to save the output
$fileName = Save-File $fileName

$data = @()

foreach($server in $serverList) {
	$OS = ""
	$IISADMINStatus = ""
	$SMS_EXECUTIVEStatus = ""
	$W3SvcStatus = ""
	$ReportServerStatus = ""
	$SQLServerStatus = ""
	$ErrorMessage = ""
	
	Try{
		$OS = (get-wmiobject -computername $server -class Win32_OperatingSystem).caption
		$IISADMINStatus = (Get-Service -computername $server | Where-Object {$_.name -eq "IISADMIN"}).status
		$SMS_EXECUTIVEStatus = (Get-Service -computername $server | Where-Object {$_.name -eq "SMS_EXECUTIVE"}).status
		$W3SvcStatus = (Get-Service -computername $server | Where-Object {$_.name -eq "W3SVC"}).status
		$ReportServerStatus = (Get-Service -computername $server | Where-Object {$_.name -eq "ReportServer"}).status
		$SQLServerStatus = (Get-Service -computername $server | Where-Object {$_.name -eq "MSSQLSERVER"}).status
	}
	
	Catch{
		$ping = Test-Connection -ComputerName $server -Count 1 -Quiet
		if($ping){
			$ErrorMessage = $_.Exception.Message
		}
		else{
			$ErrorMessage = 'Offline'
		}
	}
	
	if(!$IISADMINStatus){
	$IISADMINStatus = "Not installed"
	}
	if(!$SMS_EXECUTIVEStatus){
	$SMS_EXECUTIVEStatus = "Not installed"
	}
	if(!$W3SvcStatus){
	$W3SvcStatus = "Not installed"
	}
	if(!$ReportServerStatus){
	$ReportServerStatus = "Not installed"
	}
	if(!$SQLServerStatus){
	$SQLServerStatus = "Not installed"
	}
	
	$serverInfo = New-Object -TypeName PSObject -Property @{
		Server = $server
		OS = $OS
		IISAdminStatus = $IISADMINStatus
		SMS_EXECUTIVEStatus = $SMS_EXECUTIVEStatus
		W3SvcStatus = $W3SvcStatus
		ReportServerStatus = $ReportServerStatus
		SQLServerStatus = $SQLServerStatus
		Details = $ErrorMessage
	}
	$data += $serverInfo
	
	$data | Select Server,OS,IISADMINStatus,SMS_EXECUTIVEStatus,W3SvcStatus,ReportServerStatus,SQLServerStatus,Details | Export-Csv $fileName -noTypeInformation -append	
}