<#
.VERSION
1.0
Updated Date: Feb. 13, 2021
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

.SYNOPSIS
This script will create a new Log Analytics Workspace, new Resource Group and new Policy Assignment in the region and subscription defined
The script assumes you have at least Contributor access to the sub when running the script, if not you will receive errors and the script will fail

**NOTE: If you define a pre-existing Log Analytics Workspace or Resource Group it will use them instead of creating new

 .\Azure-SetupLAandPolicy.ps1 -rgname resource_group_name -laname log_analytics_name -pname policy_name -sname sub-name
#>
param(

 [Parameter(Mandatory=$True)]
 [string] $laname,

 [Parameter(Mandatory=$True)]
 [string] $pname,

 [Parameter(Mandatory=$True)]
 [string] $rgname,
 
 [Parameter(Mandatory=$True)]
 [string] $sname
)

#Check PowerShell is version 7.x
write-host "Checking that PowerShell is version 7.x" -ForegroundColor Green
$psver = $PSVersionTable.PSVersion
if ($psver.major -ne 7){
  write-host "PowerShell needs to be upgraded to version 7.x" -ForegroundColor Red
  Write-Host "Script is quiting until you upgrade...." -ForegroundColor Red
  Exit
}

write-host "checking if AzureAZ cmdlet is installed, if not it will install/update it as needed" -ForegroundColor Green
$azurecmdlets = Get-InstalledModule -Name Az
if ($azurecmdlets -eq $null){
    Write-Host "AzureAZ module not found, installing.....this can take a few mins to complete...." -ForegroundColor Green
    Install-Module -name az -AllowClobber -scope CurrentUser
    Write-Host "AzureAZ module installed, continuing..." -ForegroundColor Green
} else {
    $azuremodver = $azurecmdlets.version
    if ($azuremodver -ne 5.2.0){
        Write-Host "AzureAZ module out of date, updating.....this can take a few mins to complete...." -ForegroundColor Green
        Update-Module -Name Az -Force
        Write-Host "AzureAZ module updated, continuing..." -ForegroundColor Green
    }
}
write-host "AzureAZ cmdlet is current.....proceeding...." -ForegroundColor Green

$TimeStampLog = Get-Date -Format o | foreach {$_ -replace ":", "."}
$error.clear()
function Get-TimeStamp {
    return "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

$deployExtensionLogDir = split-path -parent $MyInvocation.MyCommand.Definition
$logsub = Login-azAccount -ErrorAction Stop
Get-AzLocation | Select-Object Location
$region = read-host "type Azure Region from list above to create new Resource Group and Log Analytics Workspace"
foreach ($azuresub in $sname){
    $selectSub = Select-azSubscription -SubscriptionName $azuresub -InformationAction SilentlyContinue | set-azcontext
    $subname = $azuresub
    $subid = $selectSub.Subscription.Id
    if((Test-Path -Path .\$subname) -ne 'True'){
      Write-Host "Creating new sub directory for log files" -ForegroundColor Green
      $path = new-item -Path . -ItemType "directory" -Name $subname -InformationAction SilentlyContinue -ErrorAction Stop
      $fullPath = $path.FullName
    } else {
      Write-Host "Using existing directory for logs" -ForegroundColor Green
      $path = Get-Location
      $fullPath = $path.Path + "\" + $subname 
    }
    
    #Main script logic start
    $date = date
    Write-Host "**Script started at $date" -ForegroundColor Green
    #Check to ensure valid location is selected, as Log Analytics is only support in certain regions listed below
    #eastus,westeurope,southeastasia,australiasoutheast,westcentralus,japaneast,uksouth,centralindia,
    #canadacentral,westus2,australiacentral,australiaeast,francecentral,koreacentral,northeurope,centralus,
    #eastasia,eastus2,southcentralus,northcentralus,westus,ukwest,southafricanorth,brazilsouth,switzerlandnorth,
    #switzerlandwest,germanywestcentral,australiacentral2,uaecentral,uaenorth,japanwest,brazilsoutheast,norwayeast
    Write-Host "Checking to ensure valid region is selected for Log Analytics Workspace..." -ForegroundColor Green
    $validregions = 'eastus','westeurope','southeastasia','australiasoutheast','westcentralus','japaneast','uksouth','centralindia','canadacentral','westus2','australiacentral','australiaeast','francecentral','koreacentral','northeurope','centralus','eastasia','eastus2','southcentralus','northcentralus','westus','ukwest','southafricanorth','brazilsouth','switzerlandnorth','switzerlandwest','germanywestcentral','australiacentral2','uaecentral','uaenorth','japanwest','brazilsoutheast','norwayeast'
    if ($validregions.contains($region)){
      Write-Host "Valid Region selected, script continuing..."
    } else {
      Write-Host "Invalid Region selected, please re-run using a valid region..." -ForegroundColor Red
      Exit
    }

    #Check and/or create Resource Group
    write-host "Checking if the Resource Group named: $rgname already exists" -ForegroundColor Green
    $checkrg = Get-AzResourceGroup -Name $rgname
    if ($checkrg -eq $null){
      write-host "Creating Resource Group in Region: $region" -ForegroundColor Green
      New-AzResourceGroup -Location $region -name $rgname -ErrorAction Stop
    } else {
      write-host "Resource Group named: $rgname already exsits, using exsting...."
    }

    #Check and/or create LA Workspace
    write-host "Checking if Log Analytics Workspace named: $laname already exists" -ForegroundColor Green
    $checkla = Get-AzOperationalInsightsWorkspace -Name $laname
    if ($checkla -eq $null){
      Write-Host "Creating Log Analytics Workspace named: $laname in Region: $region" -ForegroundColor Green
      $newla = New-AzOperationalInsightsWorkspace -Location $region -Name $laname -Sku Standard -ResourceGroupName $rgname -ErrorAction Stop
    } else {
      write-host "Log Analytics Workspace named: $laname already exists, using existing...."
    }
    # Enable Windows Memory Metric counters in workspace
    New-AzOperationalInsightsWindowsPerformanceCounterDataSource -ResourceGroupName $rgname -WorkspaceName $laname -ObjectName "Memory" -InstanceName "*" -CounterName "% Committed Bytes In Use" -IntervalSeconds 20 -Name "Windows Memory In Use Performance Counter"
    # Enable Linux Memory Metric counters in workspace
    New-AzOperationalInsightsLinuxPerformanceObjectDataSource -ResourceGroupName $rgname -WorkspaceName $laname -ObjectName "Memory" -InstanceName "*" -CounterName "% Used Memory" -IntervalSeconds 20 -Name "Linux Memory In Use Performance Counter"
    Enable-AzOperationalInsightsLinuxPerformanceCollection -ResourceGroupName $rgname -WorkspaceName $laname

    #Assign Policy Initiative to sub and workspace
    $psd = Get-AzPolicySetDefinition | where-object {$_.Properties.displayName -eq "Enable Azure Monitor for VMs"}
    $laid = $newla.ResourceId 
    $newlaid = @{'logAnalytics_1'=$laid}
    New-AzPolicyAssignment -Name "New Policy via PowerShell" -PolicySetDefinition $psd -Scope "/subscriptions/$subid" -PolicyParameterObject $newlaid -Location $region -AssignIdentity

Add-Content -Path .\$subname\VMsRunningPostChange_$TimeStampLog.csv -Value " "
$vmstat | out-file .\$subname\VMsRunningPostChange_$TimeStampLog.csv -Append ascii
$date = date
Write-Host "**Script finished at $date " -ForegroundColor Green
Write-Host "**Check path: ""$fullPath"" for the logs" -ForegroundColor Green
}
#END OF SCRIPT
