#The script will create a new Azure storage account in the resource group, location and subscription specified in the parameters

#example: .\AzureCreateStorageAccount.ps1 -subscriptionid SUB-ID-HERE -location AZURE-LOCATION -resroucegroup NEW-RES-GROUP-NAME - storageaccount NEW-DIAG-STORAGE

param(
 [Parameter(Mandatory=$True)]
 [string] $subscriptionId,

 [Parameter(Mandatory=$True)]
 [string] $location,

 [Parameter(Mandatory=$True)]
 [string] $resourcegroup,

 [Parameter(Mandatory=$True)]
 [string] $storageaccountname
)
$error.clear()
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
#Login Azure Account
$sub = login-azurermaccount -Subscription $subscriptionId -ErrorAction Stop

#Create new Resource Group for the new Stoage Account
$newresgroup = New-AzurermResourceGroup -Name $resourcegroup -Location $location

#Create new Storage Account for metrics
$storageAccount = New-AzurermStorageAccount -ResourceGroupName $resourcegroup -Name $storageaccountname -Location $location -Kind StorageV2 -SkuName Standard_LRS

