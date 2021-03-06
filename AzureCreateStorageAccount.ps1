<#
.VERSION
2.2 - All Turbonomic SPNs
Updated Date: Feb 7, 2020
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

#example: .\AzureCreateStorageAccount.ps1 -subscriptionid SUB-ID-HERE -location AZURE-LOCATION -resourcegroup NEW-RES-GROUP-NAME -storageaccount NEW-DIAG-STORAGE
#example: .\AzureCreateStorageAccount.ps1 -subscriptionid 82cdab36-1a2a-123a-1234-f9e83f17944b -location eastus -resourcegroup RES-NAME-01 -storageaccount diagstorage001
#>

param(
 [Parameter(Mandatory=$True)]
 [string] $subscriptionId,

 [Parameter(Mandatory=$True)]
 [string] $location,

 [Parameter(Mandatory=$True)]
 [string] $resourcegroup,

 [Parameter(Mandatory=$True)]
 [string] $storageaccount
)
$error.clear()
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
#Login Azure Account
$login = login-azurermaccount -Subscription $subscriptionId -ErrorAction Stop
$selectSub = Select-AzureRmSubscription -Subscription $subscriptionId
$subname = $selectSub.Name
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
    $newresgroup = New-AzurermResourceGroup -Name $resourcegroup -Location $location
} else {
    write-host "Resource Group already exists, using exising" -ForegroundColor Green
}
#Get List of VM's locations
$vmsloc = get-azurermvm | Select-Object -Unique -ExpandProperty "Location"
if ($vmsloc -eq $null){$vmsloc = $location} 
Add-Content -Path .\$subname\ResandStorage.csv -Value "Subscription Name,Subscription ID,Resource Group,Storage Account,Storage Location"
Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "Subscription Name,Subscription ID,Turbonomic Custom Role Name"
#Add foreach loop for creating storage account per $vmsloc variable
$count = 0
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
        $newStorage = New-AzurermStorageAccount -ResourceGroupName $resourcegroup -Name $storageaccountname -Location $storloc -Kind StorageV2 -SkuName Standard_LRS
        if(($error) -like '*is already taken*'){
            Write-Host "Storage account name ""$storageaccountname"" is already in use in Azure and is NOT unique" -ForegroundColor Red -BackgroundColor Black
            Write-Host "please re-run the script and specify a unique storage account name" -ForegroundColor Red -BackgroundColor Black
            Write-Host "**Script will now exit" -ForegroundColor Red -BackgroundColor Black
            Exit
        }
        Write-Host "Storage account name is unique, storage account created named: ""$storageaccountname"" " -ForegroundColor Green
        Add-Content -Path .\$subname\ResandStorage.csv -Value "$subname,$subscriptionId,$resourcegroup,$storageaccountname,$storloc"
    } else {
        Write-Host "Storage account named: ""$storageaccountname"" already exists, using existing instead of creating a new one" -ForegroundColor Green
        Add-Content -Path .\$subname\ResandStorage.csv -Value "$subname,$subscriptionId,$resourcegroup,$storageaccountname,$storloc"
    }
    if(($turboCustomRole = Get-AzureRmRoleDefinition -Name 'Turbonomic Operator ReadOnly') -eq $null){
        $newsub = Read-Host -Prompt 'Cannot find Turbonomic Custom Role in subscription, please enter a subscription ID that already has it listed:'
        $readNewSub = Select-AzureRmSubscription -Subscription $newsub -ErrorAction Stop
        Write-Host "Waiting 3 mins for Azure AD Sync to complete before checking again..." -ForegroundColor Green
        Start-Sleep 180
        if(($turboCustomRole = Get-AzureRmRoleDefinition -Name 'Turbonomic Operator ReadOnly') -eq $null){
            Write-Host "Still cannot find Turbonomic Custom Role in Azure AD, please run the script again after verifying role exists in the subscription" -ForegroundColor Red -BackgroundColor Black
            Write-Host "**Script will now exit" -ForegroundColor Red -BackgroundColor Black 
            Exit
        } else {
            Write-Host "Found Turbonomic Custom Role and assigning scope" -ForegroundColor Green    
            #$turboCustomRole = Get-AzureRmRoleDefinition | Where-Object{$_.Name -like '*Turbonomic*'}
            #$turboCustomRole = Get-AzureRmRoleDefinition -Name 'Turbonomic Operator ReadOnly'
            $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionId")
            $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname")
            $turboCustomRoleName = $turboCustomRole.Name
            Write-Host "Updating Turbonomic custom role scope" -ForegroundColor Green
            $setRole = Set-AzureRmRoleDefinition -Role $turboCustomRole -ErrorAction SilentlyContinue
            Start-Sleep 30
            $selectSub = Select-AzureRmSubscription -Subscription $subscriptionId
            #$turboSPNlist = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'turbonomic'}
            $turboSPNlist = get-azurermadserviceprincipal | where-object{$_.DisplayName -like 'turbo*'}
            foreach($turboSPN in $turboSPNlist){
                $turboSPNid = $turboSPN.Id.Guid
                Write-Host "Assinging Turbonomic SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReader = new-azurermroleassignment -ObjectId $turboSPNid -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustom = new-azurermroleassignment -ObjectId $turboSPNid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                }
            Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName"
        }
    } else {
        Write-Host "Found Turbonomic Custom Role and assigning scope" -ForegroundColor Green
        #$turboCustomRole = Get-AzureRmRoleDefinition | Where-Object{$_.Name -like '*Turbonomic*'}
        #$turboCustomRole = Get-AzureRmRoleDefinition -Name 'Turbonomic Operator ReadOnly'
        $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionId")
        $turboCustomRole.AssignableScopes.Add("/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname")
        $turboCustomRoleName = $turboCustomRole.Name
        Write-Host "Updating Turbonomic custom role scope" -ForegroundColor Green
        $setRole = Set-AzureRmRoleDefinition -Role $turboCustomRole -ErrorAction SilentlyContinue
        Start-Sleep 30
        #$turboSPNlist = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'turbonomic'}
        $turboSPNlist = get-azurermadserviceprincipal | where-object{$_.DisplayName -like 'turbo*'}
        foreach($turboSPN in $turboSPNlist){
            $turboSPNid = $turboSPN.Id.Guid
            Write-Host "Assinging Turbonomic SPN App Reg permissions on subscription and storage" -ForegroundColor Green
            $assignReader = new-azurermroleassignment -ObjectId $turboSPNid -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            $assignCustom = new-azurermroleassignment -ObjectId $turboSPNid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                }
        Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName"
    } 
}
$date = date
Write-Host "**Script completed at $date" -ForegroundColor Green
Write-Host "**Check path: ""$fullPath"" for the logs" -ForegroundColor Green