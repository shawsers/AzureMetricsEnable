<#
.VERSION
2.5 - All Turbonomic Prod SPNs
Updated Date: Nov. 15, 2019 - 1:20PM
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

#The script will create a new Azure storage account per location that the VM's are in and a new resrouce group unless the one provided already exists, then it will use it.
#The location specified will only be used if a new resource account is needed to be created and must be in the short name ex. eastus or westus
#It will also make the changes in the subscription specificed

#This will also add the scope of the subscription and the new storage account(s) to the Turbonomic custom role
#It will also add all of the Turbonomic Service Principals to the Turbonomic custom role scoped to the new storage account(s)
#Both above are required for Turbonomic to read the sub and read the memory metrics from the new storage account(s)

#Note when you specify the storage account name in the parameters leave off the trailing # as the script will automatically add the #1 to the end
#of the storage accounts created.  So if you have VM's in 3 locations in the sub, it will create 3 new storage accounts starting with #1, then #2, then #3

Make sure to create a file named subs-prod.txt and that it is in the directory you are running the script from.  It needs to contain a list of sub names to read in and run the script against

#You also have to specify an environment parameter now which you have to input one of the following
#PROD - which will apply the role and scope for PROD US
#PROD2 - which will apply the role and scope for PROD US 2
#PRODEU - which will apply the role and scope for PROD EU

#Make sure the sub in the parameter below is one that has already been onboarded
#example: .\AzureCreateStorageAccount.ps1 -subid SUB-ID-HERE -environment PROD
#example: .\AzureCreateStorageAccount.ps1 -subid 82cdab36-1a2a-123a-1234-f9e83f17944b -environment PROD
#>

param(
 [Parameter(Mandatory=$True)]
 [string] $subId,

 [Parameter(Mandatory=$True)]
 [string] $environment
)
$error.clear()
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
$readsubsfile = get-content -path .\subs-prod.txt
if($subId){
    $logsub = Login-AzureRmAccount -SubscriptionId $subId -ErrorAction Stop
    }
foreach ($azuresub in $readsubsfile){
    $selectSub = Select-AzureRmSubscription -SubscriptionName $azuresub -InformationAction SilentlyContinue
    $subscriptionId = $selectSub.subscription.Id
    $subname = $azuresub
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
    $resourceGroup = $storageAll.ResourceGroupName
    $storageTurboName = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup | where {$_.StorageAccountName -like '*turbo*'}
    #look at adding error checking for no Turbo storage account found
    foreach ($turbostor in $storageTurboName){
        $storageaccountname = $turbostor.StorageAccountName
        $error.clear()
        $turboCustomRole = Get-AzureRmRoleDefinition -Name 'Turbonomic Operator ReadOnly'
            Write-Host "Found Turbonomic Custom Role and assigning scope" -ForegroundColor Green    
            $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionId")
            $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname")
            $turboCustomRoleName = $turboCustomRole.Name
            Write-Host "Updating Turbonomic custom role scope" -ForegroundColor Green
            $setRole = Set-AzureRmRoleDefinition -Role $turboCustomRole -ErrorAction SilentlyContinue
            Start-Sleep 60
            $selectSub = Select-AzureRmSubscription -Subscription $subscriptionId
            if ($environment -eq "PROD"){
                $turboSPNprodus1 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'turbonomic'}
                $turboSPNprodus1id = $turboSPNprodus1.Id.Guid
                Write-Host "Assinging Turbonomic PROD SPN App Reg permissions on subscription and storage" -ForegroundColor Green
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
                Write-Host "Assinging Turbonomic Dev and Stage 3 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodus2id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodus2id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }
    }
$date = date
Write-Host "**Script completed at $date" -ForegroundColor Green
Write-Host "**Check path: ""$fullPath"" for the logs" -ForegroundColor Green
}