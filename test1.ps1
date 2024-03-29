## This script creates and applies an application manifest to PatientNow's cloud loader, preventing it from requiring admin credentials.
## Author: Chloe Bergen (https://github.com/chloebergen)

## Disables confirm dialogue, starts transcribing 
$ConfirmPreference = "None"
$transcriptPath = "C:\PN\CloudLoader\AutomationTranscript.txt"
Start-Transcript -Path $transcriptPath -Append
$timeStamp = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')]"

## Paths
$appPath = "C:\PN\CloudLoader\PatientNowCloudLoader.exe"
$appPathEXE = "C:\PN\EMR\PatientNow.exe"
$errorPath = "C:\PN\CloudLoader\AutomationError.txt"
$testPath = "$appPath.manifest"
$testPathEXE = "$appPathEXE.manifest"

# Get all processes with executable paths in the specified directory, kill them, and wait for exit before proceeding.
$processDirectory = "C:\PN\*"
$processList = Get-Process | Where-Object { $_.MainModule.FileName -like "$processDirectory*" }

foreach ($process in $processList){
    Stop-Process -InputObject $process -Force -Verbose
    $process.WaitForExit()
}

Write-Host "All processes in $processDirectory have been successfully terminated."

## Abort if the manifest file already exists.
function ManifestExists {
    if (Test-Path $testPath -PathType Leaf) {
        Write-Error "Manifest has been applied previously, deleting and reapplying manifest.."
        Remove-Item $testPath -Verbose
    } else {
        Write-Host "Manifest has not been applied previously, continuing with application.."
    }
}
ManifestExists 2>&1 > $errorPath

## Adds an application compatibility entry to prevent UAC prompts for the specified path.
Write-Host "Creating the manifest file.."
$manifestPath = "$appPath.manifest"
@"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
    <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
        <security>
            <requestedPrivileges>
                <requestedExecutionLevel level="asInvoker" uiAccess="false" />
            </requestedPrivileges>
        </security>
    </trustInfo>
</assembly>
"@ | Out-File -Encoding ASCII $manifestPath

## Applies the manifest file to the application path.
Write-Host "Applying the compatibility manifest to the application.."
cmd.exe /c "mt.exe -manifest $manifestPath -outputresource:`"$appPath`;#1" 
Write-Host "UAC prompts have been disabled for the application."


### EXE
function ManifestExistsEXE {
    if (Test-Path $testPathEXE -PathType Leaf) {
        Write-Error "Manifest has been applied previously, deleting and reapplying manifest.."
        Remove-Item $testPathEXE -Verbose
    } else {
        Write-Host "Manifest has not been applied previously, continuing with application.."
    }
}
ManifestExistsEXE 2>&1 > $errorPath

## Adds an application compatibility entry to prevent UAC prompts for the specified path.
Write-Host "Creating the manifest file.."
$manifestPath = "$appPathEXE.manifest"
@"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<assembly xmlns="urn:schemas-microsoft-com:asm.v1" manifestVersion="1.0">
    <trustInfo xmlns="urn:schemas-microsoft-com:asm.v3">
        <security>
            <requestedPrivileges>
                <requestedExecutionLevel level="asInvoker" uiAccess="false" />
            </requestedPrivileges>
        </security>
    </trustInfo>
</assembly>
"@ | Out-File -Encoding ASCII $manifestPath

## 
Write-Host $timeStamp
Stop-Transcript
$ConfirmPreference = "High"