#Search Azure subscriptions for existing Turbonomic custom role
$turboRoleSubscription = $null
foreach($azureSubscription in Get-AzureRmSubscription){
 
    #Set the script's focus one subscription at a time
    Select-AzureRmSubscription -Subscription $azureSubscription.Id
 
    #If the Azure custom role is already created, capture the subscription ID
    if(Get-AzureRmRoleDefinition | Where-Object{$_.Name -like '*Turbonomic*'}){
        $turboRoleSubscription = $azureSubscription
        if($turboRoleSubscription){
            Select-AzureRmSubscription -Subscription $azureSubscription.Id
            $targetSubID = $azureSubscription.Id
            $turboCustomRole = Get-AzureRmRoleDefinition | Where-Object{$_.Name -like '*Turbonomic*'}
            $turboCustomRole.AssignableScopes.Add("/subscriptions/$targetSubID")
        }
    }
}
 
#if an existing custom role is found, update the role's scope with target subscription info
#if($turboRoleSubscription){
#    Select-AzureRmSubscription -Subscription $azureSubscription.Id
#    $turboCustomRole = Get-AzureRmRoleDefinition | Where-Object{$_.Name -like '*Turbonomic*'}
#    $turboCustomRole.AssignableScopes.Add($targetSubID)
# 
#}