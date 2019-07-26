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
 [string] $storageaccountname,
)
$error.clear()
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
$sub = login-azurermaccount -Subscription $subscriptionId
$newresgroup = New-AzurermResourceGroup -Name $resourcegroup -Location $location
$storageAccount = New-AzurermStorageAccount -ResourceGroupName $resourcegroup -Name $storageaccountname -Location $location -Kind StorageV2 -SkuName Standard_LRS
#test commit

