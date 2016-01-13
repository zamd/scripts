[CmdletBinding()]
Param(
   [Parameter(Mandatory=$True,Position=1)]
   [string]$versionNumber
)

$virtualMachineName = "a0-"
$cloudServiceName = "tselcluster"

for ($index = 1; $index -lt 4; $index++) 
{ 
    Stop-AzureVM -ServiceName $cloudServiceName -Name "${virtualMachineName}$index"
    Save-AzureVMImage -ServiceName $cloudServiceName `
                      -Name "${virtualMachineName}$index" `
                      -NewImageName "${virtualMachineName}$index-v${versionNumber}" `
                      -NewImageLabel "${virtualMachineName}$index-v${versionNumber}" `
                      -OSState Specialized
    Start-AzureVM -ServiceName $cloudServiceName -Name "${virtualMachineName}$index"
} 