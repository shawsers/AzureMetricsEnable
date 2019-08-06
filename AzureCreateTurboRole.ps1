##Create new role in Azure specific to Turbonomic requirements
param(
 [Parameter(Mandatory=$True)]
 [string] $subscriptionId,

 [Parameter(Mandatory=$True)]
 [string] $resourcegroup,

 [Parameter(Mandatory=$True)]
 [string] $storageaccount
)
login-azurermaccount -subscriptionid $subscriptionid
$role = Get-AzureRmRoleDefinition -Name "Virtual Machine Contributor"
$role.Id = $null
$role.Name = "Turbonomic Read Memory Metrics Role"
$role.Description = "Turbonomic Permissions required to read memory metrics"
$role.Actions.Clear()
$role.Actions.Add("*/read")
#$role.Actions.Add("Microsoft.Compute/virtualMachines/write")
#$role.Actions.Add("Microsoft.Compute/virtualMachines/start/action")
#$role.Actions.Add("Microsoft.Compute/virtualMachines/deallocate/action")
#$role.Actions.Add("Microsoft.Compute/disks/write")
#$role.Actions.Add("Microsoft.Network/networkInterfaces/join/action")
$role.AssignableScopes.Clear()
$role.AssignableScopes.Add("/subscriptions/$subscriptionid")
$role.AssignableScopes.Add("/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccount")

New-AzureRmRoleDefinition -Role $role
##Add all this to the AppRegistration script
$AppName = get-azurermadserviceprincipal -DisplayName $TurboAppName
$AppID = $AppName.Id.Guid
new-azurermroleassignment -ObjectId $AppID -RoleDefinitionName "Turbonomic Role" -Scope "/subscriptions/$subscriptionid"
new-azurermroleassignment -ObjectId $AppID -RoleDefinitionName "Turbonomic Role" -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccount"