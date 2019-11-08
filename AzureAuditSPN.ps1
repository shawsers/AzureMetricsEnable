##This script audits the SPN permissions per sub and will take time to run depending on the amount of subs you have access to
## Set the export path and file name will default to the directory the script is being run in
$exportFile = ".\SPN_Scope_Sub_Role_Audit.csv"
 
## Connect to Azure
Connect-AzureRmAccount

$report=@()
foreach($azureSubscription in Get-AzureRmSubscription){
    Select-AzureRmSubscription -SubscriptionObject $azureSubscription
    foreach($assignment in Get-AzureRmRoleAssignment){
        if($assignment.DisplayName -like '*Turbo*'){
            $report += New-Object psobject -Property @{
                SubscriptionName = $azureSubscription.Name
                SubscriptionId = $azureSubscription.Id
                SubscriptionTenantId = $azureSubscription.TenantId
                SPNDisplayName = $assignment.DisplayName
                SPNRoleAssignment = $assignment.RoleDefinitionName
                ServicePrincipalId = $assignment.ObjectId
                ServicePrincipalScope = $assignment.Scope
            }
        }
    }
}
 
## Export the report
$report | Export-Csv $exportFile -NoTypeInformation
## END OF SCRIPT