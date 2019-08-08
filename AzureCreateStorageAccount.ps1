#The script will create a new Azure storage account in the resource group, location and subscription specified in the parameters

#example: .\AzureCreateStorageAccount.ps1 -subscriptionid SUB-ID-HERE -location AZURE-LOCATION -resourcegroup NEW-RES-GROUP-NAME - storageaccount NEW-DIAG-STORAGE

param(
 [Parameter(Mandatory=$True)]
 [string] $subscriptionId,

 [Parameter(Mandatory=$True)]
 [string] $location,

 [Parameter(Mandatory=$True)]
 [string] $resourcegroup,

 [Parameter(Mandatory=$True)]
 [string] $storageaccount
)
$error.clear()
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
#Login Azure Account
login-azurermaccount -Subscription $subscriptionId -ErrorAction Stop
$sub = Get-AzureRmSubscription -subscriptionid $subscriptionId
$subname = $sub.Name
Select-AzureRmSubscription -Subscription $subscriptionId
$valres = Get-AzureRmResourceGroup -Name $resourcegroup

if ($valres -eq $null){
#Create new Resource Group for the new Stoage Account
$newresgroup = New-AzurermResourceGroup -Name $resourcegroup -Location $location
}

#Get List of VM's locations
$vmsloc = get-azurermvm | Select-Object -Unique -ExpandProperty "Location"

Add-Content -Path .\ResandStorage.csv -Value "Subscription Name,Subscription ID,Resource Group,Storage Account,Storage Location"
#Add foreach loop for creating storage account per $vmsloc variable
$count = 0
foreach($storloc in $vmsloc){
$count++
$storageaccountname = $storageaccount + $count
#Create new Storage Account for metrics
New-AzurermStorageAccount -ResourceGroupName $resourcegroup -Name $storageaccountname -Location $storloc -Kind StorageV2 -SkuName Standard_LRS
Add-Content -Path .\ResandStorage.csv -Value "$subname,$subscriptionId,$resourcegroup,$storageaccountname,$storloc"
    if(Get-AzureRmRoleDefinition | Where-Object{$_.Name -like '*Turbonomic*'}){
            $turboCustomRole = Get-AzureRmRoleDefinition | Where-Object{$_.Name -like '*Turbonomic*'}
            $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionId")
            $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname")
            $turboCustomRoleName = $turboCustomRole.Name
            Set-AzureRmRoleDefinition -Role $turboCustomRole
            $turboSPNlist = get-azurermadserviceprincipal | where-object{$_.DisplayName -like '*Turbo*'}
            foreach($turboSPN in $turboSPNlist){
                $turboSPNid = $turboSPN.Id.Guid 
                new-azurermroleassignment -ObjectId $turboSPNid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname"
            }
            Add-Content -Path .\TurboRoleAddedToSubScope.csv -Value "$subname,$targetSubID,$TurboCustomRoleName"
    }
}