[CmdletBinding()]
Param(
   [Parameter(Mandatory=$True,Position=1)]
   [string]$versionNumber
)

$probePath = "/testall"
$lbSet = "a0-https"
$availabilitySet = "a0-web"
$ipRange = "172.17.0."
$virtualMachineSize = "Large"
$virtualMachineName = "a0-"
$cloudServiceName = "tselcluster-res"
$networkSubnet = "default"
$network = "*restovnet*"


# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Function: Log informational message.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
function Log([string]$msg)
{
  $now = [datetime]::Now.ToString("HH:mm:ss")
  Write-Host " ", $now, " - ", $msg
} 

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Function: Log error message.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
function LogError([string]$msg)
{
  $now = [datetime]::Now.ToString("HH:mm:ss")
  Write-Host -Fore Red " ", $now, " - ", $msg
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
# Function: Log success message.
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
function LogSuccess([string]$msg)
{
  $now = [datetime]::Now.ToString("HH:mm:ss")
  Write-Host -Fore Green " ", $now, " - ", $msg
}

function Get-VirtualNetwork 
{ 
    $vnetList = Get-AzureVNetSite 
    $vnetList = $vnetList | Where-Object { ($_.Name -ilike $network ) } 
    $vnetList | Select-Object -First(1) 
}

# Get VNET
Log "Searching for Virtual Network: $network"
$vnet = Get-VirtualNetwork
if ($vnet -eq $null) 
{ 
    LogError "Unable to find Virtual Network '$network'" 
    return
} 
$vnetId = $vnet.Id
LogSuccess "Found network: $vnetId"

Log "Removing VMs..."

for ($index = 1; $index -lt 4; $index++) 
{ 
    # Remove VM
    Remove-AzureVM -Name "${virtualMachineName}$index" -ServiceName $cloudServiceName -DeleteVHD
}

Log "Recreating VMs..."

for ($index = 1; $index -lt 4; $index++) 
{ 
    $ipAddress = 10 + $index
    $ipAddress = "${ipRange}${ipAddress}"
    $sshPort = 56780 + $index

    # Create VM
    $vm = New-AzureVMConfig -Name "${virtualMachineName}$index" -InstanceSize $virtualMachineSize -ImageName "${virtualMachineName}$index-v${versionNumber}" -AvailabilitySetName $availabilitySet |
        Add-AzureEndpoint -Name SSH -LocalPort 22 -PublicPort $sshPort -Protocol tcp |
        Add-AzureEndpoint -Name HTTPS -LocalPort 443 -PublicPort 443 -Protocol tcp -LBSetName $lbSet -ProbePath $probePath -ProbeProtocol http -ProbePort 80 |
        Set-AzureStaticVNetIP -IPAddress $ipAddress | 
        Set-AzureSubnet -SubnetNames $networkSubnet
    New-AzureVM -ServiceName $cloudServiceName -VM $vm -WaitForBoot -VNetName $vnet.Name
} 