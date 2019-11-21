<#
.VERSION
2.73 - All Turbonomic All SPNs
Updated Date: Nov. 19, 2019 - 2:02PM
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
#STAGE - which will apply the role and scope for Stage1, Dev
#STAGE2 - which will apply the role and scope for Stage2, Dev
#STAGE3 - which will apply the role and scope for Stage3, Dev

#Make sure the sub in the parameter below is one that has already been onboarded
#example: .\AzureCreateStorageAccount.ps1 -subid SUB-ID -environment PROD2
#example: .\AzureCreateStorageAccount.ps1 -subid a1555999-e2gg-5fd9-zb1a-e4food7d1a8e -environment PROD2
#>

param(
    [Parameter(Mandatory=$True)]
    [string] $subid,

    [Parameter(Mandatory=$True)]
    [string] $environment
)
$error.clear()
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
$readsubsfile = get-content -path .\subs-prod.txt
connect-azurermaccount -ErrorAction Stop
foreach ($azuresub in $readsubsfile){
    $selectSub = Select-AzureRmSubscription -SubscriptionName $azuresub -InformationAction SilentlyContinue
    $subscriptionId = $selectSub.subscription.Id
    $subname = $azuresub
    Write-Host "finding Turbo custom role" -ForegroundColor Green
    $turboCustomRole = Get-AzureRmRoleDefinition -Name 'Turbonomic Operator ReadOnly'
    $turboCustomRoleName = $turboCustomRole.Name
    write-host "starting sub: $subname now" -ForegroundColor Green
    Write-Host "checking Turbo resource groups" -ForegroundColor Green
    $storageAll = get-azurermresourcegroup | where {$_.ResourceGroupName -like '*turbo*'}
    foreach ($rsg in $storageAll){
        $resourceGroup = $rsg.ResourceGroupName
        Write-Host "checking Turbo storage accounts" -ForegroundColor Green
        $storageTurboName = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup | where {$_.StorageAccountName -like '*turbo*'}
        foreach ($turbostor in $storageTurboName){
            $storageaccountname = $turbostor.StorageAccountName
            $error.clear()
            #check for Turbonomic custom role if exists
            if($turboCustomRole -eq $null){
                $readNewSub = Select-AzureRmSubscription -Subscription $subid -ErrorAction Stop
                $turboCustomRole = Get-AzureRmRoleDefinition -Name 'Turbonomic Operator ReadOnly'
                $turboCustomRoleName = $turboCustomRole.Name
                $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionId")
                $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname")
                Write-Host "Updating Turbonomic custom role scope" -ForegroundColor Green
                $setRole = Set-AzureRmRoleDefinition -Role $turboCustomRole -ErrorAction SilentlyContinue
                Write-Host "Waiting 5 mins for Azure AD Sync to complete before checking again..." -ForegroundColor Green
                Start-Sleep 300
                $selectSub = Select-AzureRmSubscription -SubscriptionName $azuresub -InformationAction SilentlyContinue
            }
            $date = date
            Write-Host "**Script started at $date" -ForegroundColor Green
            #look at adding error checking for no Turbo storage account found
            if ($turboCustomRole -eq $null){write-host "Turbonomic Custom Role not found in sub: $subname, please onboard this sub and re-run" -ForegroundColor Red -BackgroundColor Black}
            #Write-Host "Found Turbonomic Custom Role and assigning scope" -ForegroundColor Green    
            #$turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionId")
            #$turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname")
            #Write-Host "Updating Turbonomic custom role scope" -ForegroundColor Green
            #$setRole = Set-AzureRmRoleDefinition -Role $turboCustomRole -ErrorAction SilentlyContinue
            Start-Sleep 60
            if ($environment -eq "PROD"){
                $turboSPNprodus1 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'turbonomic'}
                $turboSPNprodus1id = $turboSPNprodus1.Id.Guid
                Write-Host "Assinging Turbonomic PROD SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodus1id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodus1id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }
            if ($environment -eq "PRODEU"){
                $turboSPNprodeu = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-EU'}
                $turboSPNprodeuid = $turboSPNprodeu.Id.Guid
                Write-Host "Assinging Turbonomic PROD EU SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodeuid -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodeuid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }
            if ($environment -eq "PROD2"){
                $turboSPNprodus2 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-US-2'}
                $turboSPNprodus2id = $turboSPNprodus2.Id.Guid
                Write-Host "Assinging Turbonomic PROD2 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodus2id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodus2id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }
            if ($environment -eq "STAGE"){
                $turboSPNdev = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Dev'}
                $turboSPNdevid = $turboSPNdev.Id.Guid
                $turboSPNstage1 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-Stage'}
                $turboSPNstage1id = $turboSPNstage1.Id.Guid
                Write-Host "Assinging Turbonomic Dev and Stage 1 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderDev = new-azurermroleassignment -ObjectId $turboSPNdevid -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomDev = new-azurermroleassignment -ObjectId $turboSPNdevid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignReaderStage = new-azurermroleassignment -ObjectId $turboSPNstage1id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomStage = new-azurermroleassignment -ObjectId $turboSPNstage1id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }
            if ($environment -eq "STAGE2"){
                $turboSPNdev = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Dev'}
                $turboSPNdevid = $turboSPNdev.Id.Guid
                $turboSPNstage2 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Stage2'}
                $turboSPNstage2id = $turboSPNstage2.Id.Guid
                Write-Host "Assinging Turbonomic Dev and Stage 2 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderDev = new-azurermroleassignment -ObjectId $turboSPNdevid -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomDev = new-azurermroleassignment -ObjectId $turboSPNdevid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignReaderStage = new-azurermroleassignment -ObjectId $turboSPNstage2id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomStage = new-azurermroleassignment -ObjectId $turboSPNstage2id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }
            if ($environment -eq "STAGE3"){
                $turboSPNdev = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Dev'}
                $turboSPNdevid = $turboSPNdev.Id.Guid
                $turboSPNstage3 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Stage3'}
                $turboSPNstage3id = $turboSPNstage3.Id.Guid
                Write-Host "Assinging Turbonomic Dev and Stage 3 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderDev = new-azurermroleassignment -ObjectId $turboSPNdevid -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomDev = new-azurermroleassignment -ObjectId $turboSPNdevid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignReaderStage = new-azurermroleassignment -ObjectId $turboSPNstage3id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomStage = new-azurermroleassignment -ObjectId $turboSPNstage3id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }    
        }
    }
}
$date = date
Write-Host "**Script completed at $date" -ForegroundColor Green
Write-Host "**Check file named TurboRoleAddedToSubScope.csv for the logs" -ForegroundColor Green
#END OF SCRIPT
