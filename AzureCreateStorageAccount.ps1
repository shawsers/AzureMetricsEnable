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

#$region = get-azurermlocation | Select-Object Location
#$region.location | out-file -FilePath .\locations.txt
#$data = get-content .\locations.txt
#$question = Read-Host 'This will create a storage account per region, type YES to continue'
#if ($question = "YES"){
#foreach ($reg in $data){
#    New-AzurermStorageAccount -ResourceGroupName $resourcegroup -Name DIAGNOSTICS$reg -Location $reg -SkuName Standard_LRS -Kind StorageV2 | out-file -filepath .\$timestamp.txt -Append
#    }}
#else{
#Write-Host "Script cancelled, as input was not YES to continue" -ForegroundColor Green
#}
##$stgacct = Get-AzurermStorageAccount | ? { $_.StorageAccountName -match $storageaccountname }
##$sub | out-file -filepath .\$timestamp.txt -Append
##$stgacct | out-file -filepath .\$timestamp.txt -Append
##$error | out-file -filepath .\$timestamp.txt -Append
