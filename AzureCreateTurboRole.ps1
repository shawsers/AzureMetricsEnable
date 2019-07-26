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
$role = Get-AzureRmRoleDefinition -Name "Turbo-Role"
$role.Id = $null
$role.Name = "Turbo-Role"
$role.Description = "Turbo required permissions"
$role.Actions.Add("*/read")
$role.Actions.Add("Microsoft.Compute/virtualMachines/write")
$role.Actions.Add("Microsoft.Compute/virtualMachines/start/action")
$role.Actions.Add("Microsoft.Compute/virtualMachines/deallocte/action")
$role.Actions.Add("Microsoft.Compute/disks/write")
$role.Actions.Add("Microsoft.Network/networkInterfaces/join/action")
$role.AssignableScopes.Clear()
$role.AssignableScopes.Add("/subscriptions/$subscriptionid")
$role.AssignableScopes.Add("/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccount")

New-AzureRmRoleDefinition -Role $role