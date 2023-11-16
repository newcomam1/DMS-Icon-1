Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall')]
    [String]$MODE = 'Install'
)
$LASTEXITCODE = 0
$IntSum =0 
$targetprocesses = @(Get-WmiObject -Query "Select * FROM Win32_Process WHERE Name='outlook.exe'" -ErrorAction SilentlyContinue)
$targetprocesses1 = @(Get-WmiObject -Query "Select * FROM Win32_Process WHERE Name='winword.exe'" -ErrorAction SilentlyContinue)
$targetprocesses2 = @(Get-WmiObject -Query "Select * FROM Win32_Process WHERE Name='excel.exe'" -ErrorAction SilentlyContinue)
$targetprocesses3 = @(Get-WmiObject -Query "Select * FROM Win32_Process WHERE Name='acrobat.exe'" -ErrorAction SilentlyContinue)
$targetprocesses4 = @(Get-WmiObject -Query "Select * FROM Win32_Process WHERE Name='powerpnt.exe'" -ErrorAction SilentlyContinue)
$IntSum = $targetprocesses.Count + $targetprocesses1.Count + $targetprocesses2.Count + $targetprocesses3.Count + $targetprocesses4.Count
Write-Output "INTSUM=$INTSUM"
if ($IntSum -eq 0) {
    Try {
        Write-Output "No usage of APPS, running without SerivuceUI"
        if ($MODE -eq 'Uninstall'){
            Write-Output "No usage of APPS, running UNINSTALL without ServiceUI"
			$process = Start-Process Deploy-Application.exe -PassThru -Wait -ArgumentList '-DeploymentType "Uninstall" -DeployMode "NonInteractive" -AllowRebootPassThru'
		}
		else {
			Write-Output "No usage of APPS, running INSTALL without ServiceUI"
            $process = Start-Process Deploy-Application.exe -PassThru -Wait -ArgumentList '-DeploymentType "Install" -DeployMode "NonInteractive" -AllowRebootPassThru'
		}
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $ErrorMessage
    }
}
else {
    Foreach ($targetprocess in $targetprocesses) {
        $Username = $targetprocesses.GetOwner().User
        Write-output "$Username logged in, running with SerivuceUI"
    }
    Try {
        if ($MODE -eq 'Uninstall'){
			Write-Output "APPS in use, running UNINSTALL with ServiceUI"
			        .\ServiceUI.exe -Process:explorer.exe Deploy-Application.exe -AllowRebootPassThru -DeploymentType "Uninstall"
		}
		else {
			Write-Output "APPS in use, running INSTALL with ServiceUI"
			        .\ServiceUI.exe -Process:explorer.exe Deploy-Application.exe -AllowRebootPassThru

		}
        ## .\ServiceUI.exe -Process:explorer.exe Deploy-Application.exe
    }
    Catch {
        $ErrorMessage = $_.Exception.Message
        $ErrorMessage
    }
}
Write-Output "Install Exit Code = $LASTEXITCODE"
            if($LASTEXITCODE -eq 0){
            $LASTEXITCODE = 3010
            }
Write-Output "Exit Code = $LASTEXITCODE"
Exit $LASTEXITCODE
