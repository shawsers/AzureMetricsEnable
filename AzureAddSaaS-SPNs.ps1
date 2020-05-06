<#
.VERSION
3.1 - Add Turbonomic SaaS SPNs
Updated Date: May 5, 2020
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

#This script will add the SaaS SPN's to the Azure subs storage accounts
#This script also assumes you have an RG and Storage account already created both with "turbo" in the name of them.

#Make sure the sub in the parameter below is one that has already been onboarded
#example: .\AzureCreateStorageAccount.ps1
#>
$logsub = Login-AzureRmAccount -ErrorAction Stop -InformationAction SilentlyContinue
$error.clear()
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
#$readsubsfile = get-content -path .\subs-prod.txt
$readsubsfile = get-AzureRmSubscription
foreach ($azuresub in $readsubsfile){
    $subname = $azuresub.subscriptionname
    $subscriptionId = $azuresub.subscription.Id
    $selectSub = Select-AzureRmSubscription -SubscriptionId $subscriptionId -InformationAction SilentlyContinue
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
    } else {
    foreach ($turborg in $storageAll){
        $resourceGroup = $turborg.ResourceGroupName
        $storageTurboName = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup | where {$_.StorageAccountName -like '*turbo*'}
        if ($storageTurboName -eq $null){
            Write-Host "No Turbonomic Storage Account found in $subname ....exiting script" -ForegroundColor Red -BackgroundColor Black
        } else {
        #look at adding error checking for no Turbo storage account found
        foreach ($turbostor in $storageTurboName){
            $storageaccountname = $turbostor.StorageAccountName
            $error.clear()
            $turboCustomRoleName = "Reader and Data Access"
            $selectSub = Select-AzureRmSubscription -Subscription $subscriptionId
            if ($environment -eq "PROD1"){
                $turboSPNprodus1 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'turbonomic'}
                $turboSPNprodus1id = $turboSPNprodus1.Id.Guid
                Write-Host "Assinging Turbonomic PROD 1 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodus1id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodus1id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }
            if ($environment -eq "PRODEU"){
                $turboSPNprodeu = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-EU'}
                $turboSPNprodeuid = $turboSPNprodeu.Id.Guid
                Write-Host "Assinging Turbonomic PROD EU SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodeuid -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodeuid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }
            if ($environment -eq "PROD2"){
                $turboSPNprodus2 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-US-2'}
                $turboSPNprodus2id = $turboSPNprodus2.Id.Guid
                Write-Host "Assinging Turbonomic PROD 2 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodus2id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodus2id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
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
}
