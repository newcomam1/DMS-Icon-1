<#
.SYNOPSIS

PSApppDeployToolkit - This script performs the installation or uninstallation of an application(s).

.DESCRIPTION

- The script is provided as a template to perform an install or uninstall of an application(s).
- The script either performs an "Install" deployment type or an "Uninstall" deployment type.
- The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.

The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.

PSApppDeployToolkit is licensed under the GNU LGPLv3 License - (C) 2023 PSAppDeployToolkit Team (Sean Lillis, Dan Cunningham and Muhammad Mashwani).

This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the
Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
for more details. You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.

.PARAMETER DeploymentType

The type of deployment to perform. Default is: Install.

.PARAMETER DeployMode

Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.

.PARAMETER AllowRebootPassThru

Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.

.PARAMETER TerminalServerMode

Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Desktop Session Hosts/Citrix servers.

.PARAMETER DisableLogging

Disables logging to file for the script. Default is: $false.

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"

.EXAMPLE

powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"

.EXAMPLE

Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"

.INPUTS

None

You cannot pipe objects to this script.

.OUTPUTS

None

This script does not generate any output.

.NOTES

Toolkit Exit Code Ranges:
- 60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
- 69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
- 70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1

.LINK

https://psappdeploytoolkit.com
#>


[CmdletBinding()]
Param (
    [Parameter(Mandatory = $false)]
    [ValidateSet('Install', 'Uninstall', 'Repair')]
    [String]$DeploymentType = 'Install',
    [Parameter(Mandatory = $false)]
    [ValidateSet('Interactive', 'Silent', 'NonInteractive')]
    [String]$DeployMode = 'Interactive',
    [Parameter(Mandatory = $false)]
    [switch]$AllowRebootPassThru = $false,
    [Parameter(Mandatory = $false)]
    [switch]$TerminalServerMode = $false,
    [Parameter(Mandatory = $false)]
    [switch]$DisableLogging = $false
)

Try {
    ## Set the script execution policy for this process
    Try {
        Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop'
    }
    Catch {
    }

    ##*===============================================
    ##* VARIABLE DECLARATION
    ##*===============================================
    ## TODO Variables: Application
    [String]$appVendor = 'Comcast'
    [String]$appName = 'DMS Icon'
    [String]$appVersion = '1.0'
    [String]$appArch = ''
    [String]$appLang = 'EN'
    [String]$appRevision = '01'
    [String]$appScriptVersion = '1.0.0'
    [String]$appScriptDate = '11/16/2023'
    [String]$appScriptAuthor = 'ANDY NEWCOMBE'
    ##*===============================================
    ## Variables: Install Titles (Only set here to override defaults set by the toolkit)
    [String]$installName = ''
    [String]$installTitle = ''

    ##* Do not modify section below
    #region DoNotModify

    ## Variables: Exit Code
    [Int32]$mainExitCode = 0

    ## Variables: Script
    [String]$deployAppScriptFriendlyName = 'Deploy Application'
    [Version]$deployAppScriptVersion = [Version]'3.9.3'
    [String]$deployAppScriptDate = '02/05/2023'
    [Hashtable]$deployAppScriptParameters = $PsBoundParameters

    ## Variables: Environment
    If (Test-Path -LiteralPath 'variable:HostInvocation') {
        $InvocationInfo = $HostInvocation
    }
    Else {
        $InvocationInfo = $MyInvocation
    }
    [String]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

    ## Dot source the required App Deploy Toolkit Functions
    Try {
        [String]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
        If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) {
            Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]."
        }
        If ($DisableLogging) {
            . $moduleAppDeployToolkitMain -DisableLogging
        }
        Else {
            . $moduleAppDeployToolkitMain
        }
    }
    Catch {
        If ($mainExitCode -eq 0) {
            [Int32]$mainExitCode = 60008
        }
        Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
        ## Exit the script, returning the exit code to SCCM
        If (Test-Path -LiteralPath 'variable:HostInvocation') {
            $script:ExitCode = $mainExitCode; Exit
        }
        Else {
            Exit $mainExitCode
        }
    }

    #endregion
    ##* Do not modify section above
    ##*===============================================
    ##* END VARIABLE DECLARATION
    ##*===============================================

    If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
        ##*===============================================
        ##* PRE-INSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Installation'

        ## TODO Show Welcome Message, close Internet Explorer if required, allow up to 3 deferrals, verify there is enough disk space to complete the install, and persist the prompt
        ## Show-InstallationWelcome -CloseApps 'iexplore' -AllowDefer -DeferTimes 3 -CheckDiskSpace -PersistPrompt
        ## EXAMPLES ##
		# TODO REMOVE DMS SHORTCUTS
        Show-InstallationProgress -StatusMessage "Removing Previous Shortcuts..."
		$shortcuts = "$env:Public\Desktop\IMANAGE*.LNK", "$env:Public\Desktop\THINCLIENT*.LNK", "$env:Public\Desktop\DESKSITE*.LNK", "$env:Public\Desktop\CLOUD DMS*.LNK", "$env:Public\Desktop\DMS.LNK"
		Get-childitem -path $($shortcuts) | ForEach-Object { Remove-Item $_ }
		Show-InstallationProgress -StatusMessage "Applying New Shortcuts..."

		$iconDIR1 = "$envProgramFiles\iManage"
		$iconFile1 = "$iconDIR1\iManage Work.ico"
		Copy-File -Path "$dirfiles\iManage Work.ico" -Destination $iconfile1 -ContinueOnError $true -ContinueFileCopyOnError $true
    
		if(test-path $iconFile1)
		{
		    ##***To Create a shortcut***
		    $CheckDIR1 = "$envProgramFiles\Google\Chrome\Application"
			$CheckFile1 = "$CheckDir1\chrome.exe"
			if(test-path $CheckFile1)
			{ 
				Write-Host "Creating CHROME 64BIT ICON"
				#https://cloudimanage.com/auth?auto_submit=true&remember_email=true#/login
				#New-Shortcut -Path "$envCommonDesktop\DMS.lnk" -TargetPath "$Checkfile1" -IconLocation "$iconFile1" -Arguments "https://cloudimanage.com/"  -Description 'DMS Work 10' -WorkingDirectory "$envHomeDrive\$envHomePath"
				New-Shortcut -Path "$envCommonDesktop\DMS.lnk" -TargetPath "$Checkfile1" -IconLocation "$iconFile1" -Arguments "https://cloudimanage.com/auth?auto_submit=true&remember_email=true#/login"  -Description 'DMS Work 10' -WorkingDirectory "$envHomeDrive\$envHomePath"
			}
			$CheckDIR1 = "$envProgramFilesX86\Google\Chrome\Application"
			$CheckFile1 = "$CheckDir1\chrome.exe"
						Write-Host "Creating CHROME 32BIT ICON $CheckFile1"

			if(test-path $CheckFile1)
			{ 
				Write-Host "Creating CHROME 32BIT ICON"
				#New-Shortcut -Path "$envCommonDesktop\DMS.lnk" -TargetPath "$Checkfile1" -IconLocation "$iconFile1" -Arguments "https://cloudimanage.com/"  -Description 'DMS Work 10' -WorkingDirectory "$envHomeDrive\$envHomePath"
				New-Shortcut -Path "$envCommonDesktop\DMS.lnk" -TargetPath "$Checkfile1" -IconLocation "$iconFile1" -Arguments "https://cloudimanage.com/auth?auto_submit=true&remember_email=true#/login"  -Description 'DMS Work 10' -WorkingDirectory "$envHomeDrive\$envHomePath"
			}
		}


        ## <Perform Installation tasks here>


      

        ##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

		## TODO EXAMPLE WRITE INSTALLATION TATTOO IN REGISTR
        

        $CheckForReg = 'HKLM:SOFTWARE\Comcast Legal\DMS'
        if (test-path $CheckForReg) { 
            Write-Host "Found $CheckForReg"
            Remove-RegistryKey -Key 'HKLM:SOFTWARE\Comcast Legal\DMSICON' -recurse -ErrorAction SilentlyContinue
        }
        [datetime]$InstallDateTime = Get-Date
        Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Comcast Legal\DMSICON' -Name 'APP_NAME' -Value $appname -Type String
        Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Comcast Legal\DMSICON' -Name 'INSTALL_TYPE' -Value $installTitle -Type String
        Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Comcast Legal\DMSICON' -Name 'INSTALLDATE' -Value $InstallDateTime -Type String
        Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Comcast Legal\DMSICON' -Name 'PACKAGE_VERSION' -Value $appRevision -Type String
        Set-RegistryKey -Key 'HKEY_LOCAL_MACHINE\SOFTWARE\Comcast Legal\DMSICON' -Name 'INSTALL_MODE' -Value $DeployMode -Type String

        
        [int32]$mainExitCode = 0

    }
    ElseIf ($deploymentType -ieq 'Uninstall') {
        ##*===============================================
        ##* PRE-UNINSTALLATION
        ##*===============================================
        [String]$installPhase = 'Pre-Uninstallation'

        ## TODO Show Welcome Message, close Internet Explorer with a 60 second countdown before automatically closing

        ## Show Progress Message (with the default message)


    }
    ElseIf ($deploymentType -ieq 'Repair') {
        ##*===============================================
        ##* PRE-REPAIR
        ##*===============================================
        [String]$installPhase = 'Pre-Repair'

        ##*===============================================
        ##* POST-REPAIR
        ##*===============================================
        [String]$installPhase = 'Post-Repair'

        ## <Perform Post-Repair tasks here>


    }
    ##*===============================================
    ##* END SCRIPT BODY
    ##*===============================================

    ## Call the Exit-Script function to perform final cleanup operations
    Exit-Script -ExitCode $mainExitCode
}
Catch {
    [Int32]$mainExitCode = 60001
    [String]$mainErrorMessage = "$(Resolve-Error)"
    Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
    Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
    Exit-Script -ExitCode $mainExitCode
}
