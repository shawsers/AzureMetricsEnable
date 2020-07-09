<#
.VERSION
1.0 - Add Turbonomic ParkMyCloud (PMC) SPNs
Updated Date: July 9, 2020
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

#This script will add the Turbonomic PMC SPN as Reader to the Azure subs in the subs.txt input file

#Make sure the subs.txt file exists and has the list of subs you want to run the script against in it
#example: .\Azure-Add-PMC-SPN-FromList.ps1
#>
$logsub = Login-AzureRmAccount -ErrorAction Stop -InformationAction SilentlyContinue
$error.clear()
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
$readsubsfile = get-content -path .\subs.txt
foreach ($azuresub in $readsubsfile){
    $selectSub = Select-AzureRmSubscription -Subscriptionname $azuresub -InformationAction SilentlyContinue | set-azurermcontext
    $subscriptionId = $selectSub.subscription.Id
    $subname = $selectSub.subscriptionname
    $date = date
    Write-Host "**Script started at $date" -ForegroundColor Green
    if((Test-Path -Path .\$subname) -ne 'True'){
        Write-Host "Creating new sub directory for log files" -ForegroundColor Green
        $path = new-item -Path . -ItemType "directory" -Name $subname -InformationAction SilentlyContinue -ErrorAction Stop
        $fullPath = $path.FullName
    } else {
        Write-Host "Using existing directory for logs" -ForegroundColor Green
        $path = Get-Location
        $fullPath = $path.Path + "\" + $subname 
    }
                    $error.clear()
                    $turboSaaSDev = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-PMC'}
                    $turboSaaSDevid = $turboSaaSDev.Id.Guid
                    Write-Host "Assinging Turbonomic SaaS SPN permissions and storage account: $storageaccountname" -ForegroundColor Green
                    $assignSaaSDevC = new-azurermroleassignment -ObjectId $turboSaaSDevid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                    $assignSaaSProdC = new-azurermroleassignment -ObjectId $turboSaaSProdid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                    Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$turboCustomRoleName,$environment"
                    Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$error"
                    $error.clear()                
}
$date = date
Write-Host "**Script completed at $date" -ForegroundColor Green
Write-Host "**Check path: ""$fullPath"" for the logs" -ForegroundColor Green
#END SCRIPT
