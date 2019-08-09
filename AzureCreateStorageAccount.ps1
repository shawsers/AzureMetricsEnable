#The script will create a new Azure storage account per location that the VM's are in and a new resrouce group unless the one provided already exists, then it will use it.
#The location specified will only be used if a new resource account is needed to be created and must be in the short name ex. eastus or westus
#It will also make the changes in the subscription specificed

#This will also add the scope of the subscription and the new storage account(s) to the Turbonomic custom role
#It will also add the Turbonomic Service Principal to the Turbonomic custom role scoped to the new storage account(s)
#Both above are required for Turbonomic to read the sub and read the memory metrics from the new storage account(s)

#Note when you specify the storage account name in the parameters leave off the trailing # as the script will automatically add the #1 to the end
#of the storage accounts created.  So if you have VM's in 3 locations in the sub, it will create 3 new storage accounts starting with #1, then #2, then #3

#example: .\AzureCreateStorageAccount.ps1 -subscriptionid SUB-ID-HERE -location AZURE-LOCATION -resourcegroup NEW-RES-GROUP-NAME - storageaccount NEW-DIAG-STORAGE
#example: .\AzureCreateStorageAccount.ps1 -subscriptionid 82cdab36-1a2a-123a-1234-f9e83f17944b -location eastus -resourcegroup RES-NAME-01 - storageaccount diagstorage00

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
            #Uncomment for Prod only - $turboSPNlist = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'turbonomic'}
            $turboSPNlist = get-azurermadserviceprincipal | where-object{$_.DisplayName -like '*Turbo*'}
            foreach($turboSPN in $turboSPNlist){
                $turboSPNid = $turboSPN.Id.Guid 
                new-azurermroleassignment -ObjectId $turboSPNid -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid"
                new-azurermroleassignment -ObjectId $turboSPNid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname"
            }
            Add-Content -Path .\TurboRoleAddedToSubScope.csv -Value "$subname,$targetSubID,$TurboCustomRoleName"
    }
}