<#
.VERSION
3.2 - Add Turbonomic SaaS SPNs
Updated Date: May 6, 2020
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

#This script will add the SaaS SPN's to the Azure subs storage accounts in all Azure subs you have elevated access to
#This script also assumes you have an RG and Storage account already created both with "turbo" in the name of them.

#Make sure the sub.txt file exists and has the list of subs you want to run the script against in it
#example: .\AzureCreateStorageAccount.ps1
#>
$logsub = Login-AzureRmAccount -ErrorAction Stop -InformationAction SilentlyContinue
$error.clear()
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
$readsubsfile = get-content -path .\subs.txt
foreach ($azuresub in $readsubsfile){
    $selectSub = Select-AzureRmSubscription -Subscriptionname $azuresub -InformationAction SilentlyContinue
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
    $storageAll = get-azurermresourcegroup | where {$_.ResourceGroupName -like '*turbo*'}
    if ($storageAll -eq $null){
        Write-Host "No Turbonomic RG found in $subname ....exiting script" -ForegroundColor Red -BackgroundColor Black
        Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,NO TURBO RG FOUND"
    } else {
        foreach ($turborg in $storageAll){
            $resourceGroup = $turborg.ResourceGroupName
            $storageTurboName = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup | where {$_.StorageAccountName -like '*turbo*'}
            if ($storageTurboName -eq $null){
                Write-Host "No Turbonomic Storage Account found in $subname ....exiting script" -ForegroundColor Red -BackgroundColor Black
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,NO TURBO STORAGE FOUND"
            } else {
                #look at adding error checking for no Turbo storage account found
                foreach ($turbostor in $storageTurboName){
                    $storageaccountname = $turbostor.StorageAccountName
                    $error.clear()
                    $turboCustomRoleName = "Reader and Data Access"
                    $turboSaaSDev = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-SaaS-Dev'}
                    $turboSaaSDevid = $turboSaaSDev.Id.Guid
                    $turboSaaSProd = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-SaaS-Prod'}
                    $turboSaaSProdid = $turboSaaSProd.Id.Guid
                    Write-Host "Assinging Turbonomic SaaS SPN permissions and storage account: $storageaccountname" -ForegroundColor Green
                    $assignSaaSDevC = new-azurermroleassignment -ObjectId $turboSaaSDevid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                    $assignSaaSProdC = new-azurermroleassignment -ObjectId $turboSaaSProdid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                    Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$turboCustomRoleName,$environment"
                    Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$error"
                    $error.clear()                
                }
            }
        }
    }
}
$date = date
Write-Host "**Script completed at $date" -ForegroundColor Green
Write-Host "**Check path: ""$fullPath"" for the logs" -ForegroundColor Green
#END SCRIPT
