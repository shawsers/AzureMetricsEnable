#The script will create a new Azure storage account in the resource group, location and subscription specified in the parameters

#example: .\AzureCreateStorageAccount.ps1 -subscriptionid SUB-ID-HERE -location AZURE-LOCATION -resourcegroup NEW-RES-GROUP-NAME - storageaccount NEW-DIAG-STORAGE

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
login-azurermaccount -Subscription $subscriptionId -ErrorAction Stop
$sub = Get-AzureRmSubscription 
$subname = $sub.Name
#Create new Resource Group for the new Stoage Account
$newresgroup = New-AzurermResourceGroup -Name $resourcegroup -Location $location

#Get List of VM's locations
$vmsloc = get-azurermvm | Select-Object -Unique -ExpandProperty "Location"

Add-Content -Path .\ResandStorage.csv -Value "Subscription Name,Subscription ID,Resource Group,Storage Account,Storage Location"
#Add foreach loop for creating storage account per $vmsloc variable
$count = 0
foreach($storloc in $vmsloc){
$count++
$storageaccountname = $storageaccount + $count
#Create new Storage Account for metrics
New-AzurermStorageAccount -ResourceGroupName $resourcegroup -Name $storageaccountname -Location $location -Kind StorageV2 -SkuName Standard_LRS

Add-Content -Path .\ResandStorage.csv -Value "$subname,$subscriptionId,$resourcegroup,$storageaccountname,$storloc"
}