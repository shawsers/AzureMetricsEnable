<#
.VERSION
1.0
Updated Date: Feb. 7, 2020
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

#The script will create a new Azure storage account per location that the VM's are in and a new resrouce group unless the one provided already exists, then it will use it.
#The location specified will only be used if a new resource account is needed to be created and must be in the short name ex. eastus or westus
#It will also make the changes in the subscription specificed

#This will also add the scope of the subscription and the new storage account(s) to the Turbonomic custom role
#It will also add all of the Turbonomic Service Principals to the Turbonomic custom role scoped to the new storage account(s)
#Both above are required for Turbonomic to read the sub and read the memory metrics from the new storage account(s)

#Make sure to specify a unique storage account name, otherwise the script will exit/stop

#You also have to specify an environment parameter now which you have to input one of the following

#example: .\AzureCreateStorageAccount.ps1 -subscriptionid SUB-ID-HERE -location AZURE-LOCATION -resourcegroup NEW-RES-GROUP-NAME -storageaccount NEW-DIAG-STORAGE -spn TURBO-SPN-NAME
#example: .\AzureCreateStorageAccount.ps1 -subscriptionid 82cdab36-1a2a-123a-1234-f9e83f17944b -location eastus -resourcegroup RES-NAME-01 -storageaccount turbostorage001 -spn turbonomic_spn
#>

param(
 [Parameter(Mandatory=$True)]
 [string] $subscriptionId,

 [Parameter(Mandatory=$True)]
 [string] $location,

 [Parameter(Mandatory=$True)]
 [string] $resourcegroup,

 [Parameter(Mandatory=$True)]
 [string] $storageaccount,

 [Parameter(Mandatory=$True)]
 [string] $spn
)
$error.clear()
#check if Azure cmdlets are installed, if not install or update them
write-host "checking if AzureRM cmdlet is install, if not it will install/update it as needed" -ForegroundColor Green
$azurecmdlets = Get-InstalledModule -Name AzureRM
if ($azurecmdlets -eq $null){
    Write-Host "AzureRM module not found, installing.....this can take a few mins to complete...." -ForegroundColor Green
    Install-Module -name azurerm -scope CurrentUser
    Write-Host "AzureRM module installed, continuing..." -ForegroundColor Green
} else {
    $azuremodver = get-installedmodule -Name AzureRM -MinimumVersion 6.13.1 -ErrorAction SilentlyContinue
    if ($azuremodver -eq $null){
        Write-Host "AzureRM module out of date, updating.....this can take a few mins to complete...." -ForegroundColor Green
        Update-Module -Name AzureRM -Force
        Write-Host "AzureRM module updated, continuing..." -ForegroundColor Green
    }
}
write-host "AzureRM cmdlet is current.....proceeding...." -ForegroundColor Green
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
    $newresgroup = New-AzurermResourceGroup -Name $resourcegroup -Location $location -ErrorAction Stop
} else {
    write-host "Resource Group already exists, using exising" -ForegroundColor Green
}
#Get List of VM's locations
#$vmsloc = get-azurermvm | Select-Object -Unique -ExpandProperty "Location"
#if ($vmsloc -eq $null){$vmsloc = $location} 
$vmsloc = $location
Add-Content -Path .\$subname\ResandStorage.csv -Value "Subscription Name,Subscription ID,Resource Group,Storage Account,Storage Location,Storage Path"
Add-Content -Path .\$subname\TurboRoleAddedToStorage.csv -Value "Subscription Name,Subscription ID,Turbonomic Role Name, SPN Name"
#Add foreach loop for creating storage account per $vmsloc variable
#$count = 0
$error.clear()
 #   $count++
 #   $storageaccountname = $storageaccount + $count
    $storageaccountname = $storageaccount
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
    $turboCustomRoleName = "Reader and Data Access"
            if (($turboSPNprodus1 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq $spn}) -eq $null){
                Write-Host "Turbonomic SPN name $spn not found.....exiting script now....."
                Exit
            } else {
                $turboSPNprodus1id = $turboSPNprodus1.Id.Guid
                Write-Host "Assinging Turbonomic SPN named $spn with Reader and Data Access permissions on storage named $storageaccountname" -ForegroundColor Green
                $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodus1id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\$subname\TurboRoleAddedToStorage.csv -Value "$subname,$subscriptionId,$turboCustomRoleName,$spn"
                Add-Content -Path .\$subname\TurboRoleAddedToStorage.csv -Value "$error"
                $error.clear()
            }
$date = date
Write-Host "**Script completed at $date" -ForegroundColor Green
Write-Host "**Check path: ""$fullPath"" for the logs" -ForegroundColor Green
