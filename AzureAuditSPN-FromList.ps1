##This script audits the SPN permissions per sub that is listed in the input file example in script is prodsub.txt and must be in the path where the script is running from
## Set the export path and file name will default to the directory the script is being run in
$exportFile = ".\SPN_Scope_Sub_Role_Audit.csv"
 
## Connect to Azure
Connect-AzureRmAccount
$prodsubs = Get-Content -Path .\prodsub.txt
$report=@()
foreach($azureSubscription in $prodsubs){
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
Write-Host "make sure to check the running directory for the output file name" -ForegroundColor Green 
## Export the report
$report | Export-Csv $exportFile -NoTypeInformation
## END OF SCRIPT