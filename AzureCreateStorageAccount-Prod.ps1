<#
.VERSION
2.5 - All Turbonomic Prod SPNs
Updated Date: Nov. 15, 2019 - 12:05PM
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

#You also have to specify an environment parameter now which you have to input one of the following
#PROD - which will apply the role and scope for PROD US
#PROD2 - which will apply the role and scope for PROD US 2
#PRODEU - which will apply the role and scope for PROD EU

#example: .\AzureCreateStorageAccount.ps1 -subscriptionid SUB-ID-HERE -environment PROD
#example: .\AzureCreateStorageAccount.ps1 -subscriptionid 82cdab36-1a2a-123a-1234-f9e83f17944b -environment PROD
#>

param(
 [Parameter(Mandatory=$True)]
 [string] $subscriptionId,

 [Parameter(Mandatory=$True)]
 [string] $environment
)
$error.clear()
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
#Login Azure Account
login-azurermaccount -Subscription $subscriptionId -ErrorAction Stop

$sub = Get-AzureRmSubscription -subscriptionid $subscriptionId
$subname = $sub.Name
$selectSub = Select-AzureRmSubscription -Subscription $subscriptionId
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

if (($valres = Get-AzureRmResourceGroup -Name $resourcegroup -ErrorAction SilentlyContinue) -eq $null){
    Write-Host "Resource Group does not exist, creating new one" -ForegroundColor Green
    #Create new Resource Group for the new Stoage Account
    $newresgroup = New-AzurermResourceGroup -Name $resourcegroup -Location $location -ErrorAction Stop
} else {
    write-host "Resource Group already exists, using exising" -ForegroundColor Green
}
#Get List of VM's locations
#$vmsloc = get-azurermvm | Select-Object -Unique -ExpandProperty "Location"
#if ($vmsloc -eq $null){$vmsloc = $location} 
$vmsloc = $location
Add-Content -Path .\$subname\ResandStorage.csv -Value "Subscription Name,Subscription ID,Resource Group,Storage Account,Storage Location,Storage Path"
Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "Subscription Name,Subscription ID,Turbonomic Custom Role Name, SPN Name"
#Add foreach loop for creating storage account per $vmsloc variable
$count = 0
$error.clear()
foreach($storloc in $vmsloc){
    $count++
    $storageaccountname = $storageaccount + $count
    #Create new Storage Account for metrics
    $getStorage = get-azurermresourcegroup | get-azurermstorageaccount -name $storageaccountname -ErrorAction SilentlyContinue
    if ($getStorage -eq $null){
        Write-Host "Storage account does not exist in the subscription" -ForegroundColor Green
        Write-Host "Checking if storage account is unique in Azure..."
        #Creating new storage account
        $selectSub = Select-AzureRmSubscription -Subscription $subscriptionId
        $error.clear()
        $newStorage = New-AzurermStorageAccount -ResourceGroupName $resourcegroup -Name $storageaccountname -Location $storloc -Kind StorageV2 -SkuName Standard_LRS -EnableHttpsTrafficOnly $true -ErrorAction Stop
        if(($error) -like '*is already taken*'){
            Write-Host "Storage account name ""$storageaccountname"" is already in use in Azure and is NOT unique" -ForegroundColor Red -BackgroundColor Black
            Write-Host "please re-run the script and specify a unique storage account name" -ForegroundColor Red -BackgroundColor Black
            Write-Host "**Script will now exit" -ForegroundColor Red -BackgroundColor Black
            Exit
        }
        $newStorageId = $newStorage.Id
        Write-Host "Storage account name is unique, storage account created named: ""$storageaccountname"" " -ForegroundColor Green
        Add-Content -Path .\$subname\ResandStorage.csv -Value "$subname,$subscriptionId,$resourcegroup,$storageaccountname,$storloc,$newStorageId"
        Add-Content -Path .\$subname\ResandStorage.csv -Value "$error"
    } else {
        Write-Host "Storage account named: ""$storageaccountname"" already exists, using existing instead of creating a new one" -ForegroundColor Green
        $getStorageId = $getStorage.Id
        Add-Content -Path .\$subname\ResandStorage.csv -Value "$subname,$subscriptionId,$resourcegroup,$storageaccountname,$storloc,$getStorageId"
        Add-Content -Path .\$subname\ResandStorage.csv -Value "$error"
    }
    $error.clear()
    if(($turboCustomRole = Get-AzureRmRoleDefinition -Name 'Turbonomic Operator ReadOnly') -eq $null){
        $newsub = Read-Host -Prompt 'Cannot find Turbonomic Custom Role in subscription, please enter a subscription ID that already has it listed:'
        $readNewSub = Select-AzureRmSubscription -Subscription $newsub -ErrorAction Stop
        #add step to add scope
        Write-Host "Waiting 3 mins for Azure AD Sync to complete before checking again..." -ForegroundColor Green
        Start-Sleep 180
        if(($turboCustomRole = Get-AzureRmRoleDefinition -Name 'Turbonomic Operator ReadOnly') -eq $null){
            Write-Host "Still cannot find Turbonomic Custom Role in Azure AD, please run the script again after verifying role exists in the subscription" -ForegroundColor Red -BackgroundColor Black
            Write-Host "**Script will now exit" -ForegroundColor Red -BackgroundColor Black 
            Exit
        } else {
            Write-Host "Found Turbonomic Custom Role and assigning scope" -ForegroundColor Green    
            $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionId")
            $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname")
            $turboCustomRoleName = $turboCustomRole.Name
            Write-Host "Updating Turbonomic custom role scope" -ForegroundColor Green
            $setRole = Set-AzureRmRoleDefinition -Role $turboCustomRole -ErrorAction SilentlyContinue
            Start-Sleep 60
            $selectSub = Select-AzureRmSubscription -Subscription $subscriptionId
            if ($environment -eq "STAGE"){
                $turboSPNprodus1 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Dev'}
                $turboSPNprodus1id = $turboSPNprodus1.Id.Guid
                $turboSPNstage1 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-Stage'}
                $turboSPNstage1id = $turboSPNstage1.Id.Guid
                Write-Host "Assinging Turbonomic Dev and Stage 1 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodus1id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodus1id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignReaderStage = new-azurermroleassignment -ObjectId $turboSPNstage1id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomStage = new-azurermroleassignment -ObjectId $turboSPNstage1id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }
            if ($environment -eq "STAGE2"){
                $turboSPNprodeu = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Dev'}
                $turboSPNprodeuid = $turboSPNprodeu.Id.Guid
                $turboSPNstage2 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Stage2'}
                $turboSPNstage2id = $turboSPNstage2.Id.Guid
                Write-Host "Assinging Turbonomic Dev and Stage 2 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodeuid -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodeuid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignReaderStage = new-azurermroleassignment -ObjectId $turboSPNstage2id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomStage = new-azurermroleassignment -ObjectId $turboSPNstage2id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }
            if ($environment -eq "STAGE3"){
                $turboSPNprodus2 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Dev'}
                $turboSPNprodus2id = $turboSPNprodus2.Id.Guid
                $turboSPNstage3 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Stage3'}
                $turboSPNstage3id = $turboSPNstage3.Id.Guid
                Write-Host "Assinging Turbonomic Dev and Stage 3 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodus2id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodus2id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignReaderStage = new-azurermroleassignment -ObjectId $turboSPNstage3id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomStage = new-azurermroleassignment -ObjectId $turboSPNstage3id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }    
        }
    } else {
        Write-Host "Found Turbonomic Custom Role and assigning scope" -ForegroundColor Green
        $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionId")
        $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname")
        $turboCustomRoleName = $turboCustomRole.Name
        Write-Host "Updating Turbonomic custom role scope" -ForegroundColor Green
        $setRole = Set-AzureRmRoleDefinition -Role $turboCustomRole -ErrorAction SilentlyContinue
        Start-Sleep 60
        if ($environment -eq "STAGE"){
            $turboSPNprodus1 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Dev'}
            $turboSPNprodus1id = $turboSPNprodus1.Id.Guid
            $turboSPNstage1 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-Stage'}
            $turboSPNstage1id = $turboSPNstage1.Id.Guid
            Write-Host "Assinging Turbonomic Prod US1 and Stage 1 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
            $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodus1id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodus1id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            $assignReaderStage = new-azurermroleassignment -ObjectId $turboSPNstage1id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            $assignCustomStage = new-azurermroleassignment -ObjectId $turboSPNstage1id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
            Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$error"
            $error.clear()
            }
        if ($environment -eq "STAGE2"){
            $turboSPNprodeu = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Dev'}
            $turboSPNprodeuid = $turboSPNprodeu.Id.Guid
            $turboSPNstage2 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Stage2'}
            $turboSPNstage2id = $turboSPNstage2.Id.Guid
            Write-Host "Assinging Turbonomic Prod EU and Stage 2 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
            $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodeuid -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodeuid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            $assignReaderStage = new-azurermroleassignment -ObjectId $turboSPNstage2id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            $assignCustomStage = new-azurermroleassignment -ObjectId $turboSPNstage2id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
            Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$error"
            $error.clear()
            }
        if ($environment -eq "STAGE3"){
            $turboSPNprodus2 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Dev'}
            $turboSPNprodus2id = $turboSPNprodus2.Id.Guid
            $turboSPNstage3 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Stage3'}
            $turboSPNstage3id = $turboSPNstage3.Id.Guid
            Write-Host "Assinging Turbonomic Prod EU and Stage 2 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
            $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodus2id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodus2id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            $assignReaderStage = new-azurermroleassignment -ObjectId $turboSPNstage3id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            $assignCustomStage = new-azurermroleassignment -ObjectId $turboSPNstage3id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
            Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$error"
            $error.clear()
            }
    } 
}
$date = date
Write-Host "**Script completed at $date" -ForegroundColor Green
Write-Host "**Check path: ""$fullPath"" for the logs" -ForegroundColor Green