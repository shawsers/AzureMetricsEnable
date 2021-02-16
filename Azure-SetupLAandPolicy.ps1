<#
.VERSION
1.0
Updated Date: Feb. 16, 2021
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

.SYNOPSIS
#NOTE - an Azure VM can only be connected to one Log Analytics workspace at a time, please validate your Azure environment first
##NOTE - before you continue make sure you actually need a new Log Analytics workspace created for your VM to be connected to
###NOTE - make sure you also need a new Azure policy created to manage connecting VM's to Log Analytics
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

write-host "Starting script pre-checks....." -ForegroundColor Green
write-host " "
#Check PowerShell is version 7.x
write-host "Checking that PowerShell version 7.x is installed..." -ForegroundColor Blue
$psver = $PSVersionTable.PSVersion
if ($psver.major -ne 7){
  write-host "PowerShell needs to be upgraded to version 7.x" -ForegroundColor Red
  Write-Host "Script is quiting until you upgrade...." -ForegroundColor Red
  Exit
}
write-host "PowerShell version 7.x found, continuing..." -ForegroundColor Green

write-host "checking if AzureAZ cmdlet is installed, if not it will install/update it as needed" -ForegroundColor Blue
$azurecmdlets = Get-InstalledModule -Name Az
if ($azurecmdlets -eq $null){
    Write-Host "AzureAZ module not found, installing.....this can take a few mins to complete...." -ForegroundColor White
    Install-Module -name az -AllowClobber -scope CurrentUser
    Write-Host "AzureAZ module installed, continuing..." -ForegroundColor Green
} else {
    $azuremodver = $azurecmdlets.version
    if ($azuremodver -ne "5.5.0"){
        Write-Host "AzureAZ module out of date, updating.....this can take a few mins to complete...." -ForegroundColor White
        Update-Module -Name Az -Force
        Write-Host "AzureAZ module updated, continuing..." -ForegroundColor Green
    }
}
write-host "AzureAZ cmdlet is current.....proceeding...." -ForegroundColor Green
write-host " "
write-host "End script pre-checks, continuing..." -ForegroundColor Green
write-host " "
$TimeStampLog = Get-Date -Format o | foreach {$_ -replace ":", "."}
$error.clear()
function Get-TimeStamp {
    return "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
}

$logsub = Login-azAccount -ErrorAction Stop
#Prompt for region selection, as only certain regions support Log Analytics
write-host "Use a valid region from the list below, as only these support Log Analytics" -ForegroundColor Green
write-host "eastus,westeurope,southeastasia,australiasoutheast,westcentralus,japaneast,uksouth,centralindia, `
canadacentral,westus2,australiacentral,australiaeast,francecentral,koreacentral,northeurope,centralus, `
eastasia,eastus2,southcentralus,northcentralus,westus,ukwest,southafricanorth,brazilsouth,switzerlandnorth, `
switzerlandwest,germanywestcentral,australiacentral2,uaecentral,uaenorth,japanwest,brazilsoutheast,norwayeast" -ForegroundColor Blue
write-host " "
$region = read-host "type Azure Region from list above to create new Resource Group and Log Analytics Workspace"
foreach ($azuresub in $sname){
    $selectSub = Select-azSubscription -SubscriptionName $azuresub -InformationAction SilentlyContinue | set-azcontext
    $subname = $azuresub
    $subid = $selectSub.Subscription.Id
    write-host " "
    #Main script logic start
    $date = date
    Write-Host "****MAIN SCRIPT STARTED at $date ****" -ForegroundColor Green
    #Check to ensure valid location is selected, as Log Analytics is only support in certain regions listed below
    #eastus,westeurope,southeastasia,australiasoutheast,westcentralus,japaneast,uksouth,centralindia,
    #canadacentral,westus2,australiacentral,australiaeast,francecentral,koreacentral,northeurope,centralus,
    #eastasia,eastus2,southcentralus,northcentralus,westus,ukwest,southafricanorth,brazilsouth,switzerlandnorth,
    #switzerlandwest,germanywestcentral,australiacentral2,uaecentral,uaenorth,japanwest,brazilsoutheast,norwayeast
    Write-Host "Checking to ensure valid region is selected for Log Analytics Workspace..." -ForegroundColor Blue
    $validregions = 'eastus','westeurope','southeastasia','australiasoutheast','westcentralus','japaneast','uksouth','centralindia','canadacentral','westus2','australiacentral','australiaeast','francecentral','koreacentral','northeurope','centralus','eastasia','eastus2','southcentralus','northcentralus','westus','ukwest','southafricanorth','brazilsouth','switzerlandnorth','switzerlandwest','germanywestcentral','australiacentral2','uaecentral','uaenorth','japanwest','brazilsoutheast','norwayeast'
    if ($validregions.contains($region)){
      Write-Host "Valid Region selected, script continuing..." -ForegroundColor Green
    } else {
      Write-Host "Invalid Region selected, please re-run using a valid region..." -ForegroundColor Red
      Exit
    }

    #Check and/or create Resource Group
    write-host "Checking if the Resource Group named: $rgname already exists..." -ForegroundColor Blue
    $checkrg = Get-AzResourceGroup -Name $rgname -ErrorAction SilentlyContinue -InformationAction SilentlyContinue -WarningAction SilentlyContinue
    if ($checkrg -eq $null){
      write-host "Resource Group doesn't exist, creating new Resource Group named: $rgname in Region: $region" -ForegroundColor Green
      $newrg = New-AzResourceGroup -Location $region -name $rgname -ErrorAction Stop
    } else {
      write-host "Resource Group named: $rgname already exsits, using exsting...."
    }

    #Check and/or create LA Workspace
    write-host "Checking if Log Analytics Workspace named: $laname already exists..." -ForegroundColor Blue
    $checkla = Get-AzOperationalInsightsWorkspace | where {$_.Name -eq $laname} -ErrorAction SilentlyContinue -InformationAction SilentlyContinue -WarningAction SilentlyContinue
    if ($checkla -eq $null){
      Write-Host "Workspace does not exist, creating new Log Analytics Workspace named: $laname in Region: $region" -ForegroundColor Green
      $newla = New-AzOperationalInsightsWorkspace -Location $region -Name $laname -Sku Standard -ResourceGroupName $rgname -ErrorAction Stop -InformationAction SilentlyContinue -WarningAction SilentlyContinue
      # Enable Windows Memory Metric counters in workspace
      write-host "Adding Windows Memory Metrics to Workspace configuration..." -ForegroundColor Green
      $newwinm = New-AzOperationalInsightsWindowsPerformanceCounterDataSource -ResourceGroupName $rgname -WorkspaceName $laname -ObjectName "Memory" -InstanceName "*" -CounterName "% Committed Bytes In Use" -IntervalSeconds 20 -Name "Windows Memory In Use Performance Counter" -ErrorAction Continue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
      # Enable Linux Memory Metric counters in workspace
      write-host "Adding Linux Memory Metrics to Workspace configuration..." -ForegroundColor Green
      $newlinm = New-AzOperationalInsightsLinuxPerformanceObjectDataSource -ResourceGroupName $rgname -WorkspaceName $laname -ObjectName "Memory" -InstanceName "*" -CounterName "% Used Memory" -IntervalSeconds 20 -Name "Linux Memory In Use Performance Counter" -ErrorAction Continue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
      $enablelinm = Enable-AzOperationalInsightsLinuxPerformanceCollection -ResourceGroupName $rgname -WorkspaceName $laname -ErrorAction Continue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
    } else {
      write-host "Log Analytics Workspace named: $laname already exists, exiting..." -ForegroundColor Red
      Exit
    }
 
    #Check and/or create Policy
    write-host "Checking if Policy named: $pname already exists..." -ForegroundColor Blue
    $checkpol = Get-AzPolicyAssignment | where {$_.Name -eq $pname} -ErrorAction SilentlyContinue -InformationAction SilentlyContinue -WarningAction SilentlyContinue
    if ($checkpol -eq $null){
      #Create new Policy and Assign Existing Azure Monitor Initiative to sub and workspace
      $psd = Get-AzPolicySetDefinition | where-object {$_.Properties.displayName -eq "Enable Azure Monitor for VMs"}
      $laid = $newla.ResourceId 
      $newlaid = @{'logAnalytics_1'=$laid}
      write-host "Policy does not exist, creating new Azure Policy named: $pname" -ForegroundColor Green
      $newpola = New-AzPolicyAssignment -Name $pname -PolicySetDefinition $psd -Scope "/subscriptions/$subid" -PolicyParameterObject $newlaid -Location $region -AssignIdentity -WarningAction SilentlyContinue -InformationAction SilentlyContinue -ErrorAction Stop
    } else {
      write-host "Azure Policy named: $pname already exists, exiting..." -ForegroundColor Red
      Exit
    }

$date = date
write-host " "
Write-Host "****SCRIPT FINISHED at: $date ****" -ForegroundColor Green
}
#END OF SCRIPT
