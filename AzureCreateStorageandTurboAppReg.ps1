##This script will create a new Azure Resrouce Group and will create a new storage account in that new resource group
##Then the script will create the Turbonomic App Registration in Azure AD and assign the required delegated permissions
##Then it will assign the Turbonomic App the "Reader" role on the subscription

##This Script will prompt for login twice which is expected and requires the powershell modules "AzureRm" and "AzureAD" to be installed

##Example how to run the script: 
##.\AzureCreateStorageandTurboAppReg.ps1 -subscriptionId SUB-ID -location AZURE-LOC -resourcegroup NEW-RES-GROUP -TurboAppName NEW-TURBO-APP -storageaccountname NEW-STORAGE

param(
 [Parameter(Mandatory=$True)]
 [string] $subscriptionId,

 [Parameter(Mandatory=$True)]
 [string] $location,

 [Parameter(Mandatory=$True)]
 [string] $resourcegroup,

 [Parameter(Mandatory=$True)]
 [string] $TurboAppName,

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

##Connect to Azure AD and create Turbonomic App Registration
$currentContext = Get-AzureRmContext
$tenantid = $currentContext.Tenant.Id
$accountid = $currentContext.Account.Id
connect-azuread -TenantId $tenantid -AccountId $accountid
$svcprincipal = Get-AzureADServicePrincipal -All $true | ? { $_.DisplayName -match "Microsoft Graph" }
$svcprincipal2 = Get-AzureADServicePrincipal -All $true | ? { $_.DisplayName -match "Windows Azure Service Management API" }

# Microsoft Graph Delegations
$reqGraph = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$reqGraph.ResourceAppId = $svcprincipal.AppId

###Windows Azure Service Management API Delegation
$reqGraph2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$reqGraph2.ResourceAppId = $svcprincipal2.AppId
$permission = $svcprincipal.Oauth2Permissions | ? { $_.Value -eq "User.Read" }
$permissionid = $permission.Id
$permission2 = $svcprincipal2.Oauth2Permissions | ? { $_.Value -eq "user_impersonation" }
$permissionid2 = $permission2.Id
$appPermission1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permissionid,"Scope"
$appPermission2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList $permissionid2,"Scope"
$reqGraph.ResourceAccess = $appPermission1
$reqGraph.ResourceAppId = $svcprincipal.AppId
$reqGraph2.ResourceAccess = $appPermission2
$reqGraph2.ResourceAppId = $svcprincipal2.AppId

#Create Turbonomic App Registration with delegations
$myApp = New-AzureADApplication -DisplayName $TurboAppName -IdentifierUris $TurboAppName -RequiredResourceAccess @($reqGraph, $reqGraph2)
start-sleep -Seconds 5
$myspn = New-AzureADServicePrincipal -AccountEnabled $true -AppId $myApp.AppId -AppRoleAssignmentRequired $false -DisplayName $TurboAppName
start-sleep -Seconds 5
#Set-AzureADApplication -ObjectId $myApp.ObjectId -RequiredResourceAccess $reqGraph2

#Create Turbonomic App Secret Key
$mySecret = New-AzureADApplicationPasswordCredential -ObjectId $myApp.ObjectId -enddate 7/20/2980 -CustomKeyIdentifier $TurboAppName
start-sleep -Seconds 5
#Create log file for output of info needed to register Azure information in Turbonomic UI
$appid = $myApp.appid
$subget = get-azurermsubscription
$subname = $subget.name
$mySecretkey = $mySecret.Value
Add-Content -Path .\TurboAppInfo.csv -Value "Subscription Name,Subscription ID,Application Name,Applicaton ID,Application Secret Key,Tenant ID,Resource Group,Storage Account"
Add-Content -Path .\TurboAppInfo.csv -Value "$subname,$subscriptionId,$TurboAppName,$appid,$mySecretkey,$tenantid,$resourcegroup,$storageaccountname"
start-sleep -Seconds 5
#Assign Turbonomic App Registration Read Only access to the subscription
while(($AppName = Get-AzurermADServicePrincipal | ? { $_.DisplayName -match $TurboAppName }) -eq $null){start-sleep 10}
start-sleep -Seconds 30
$AppObjectID = $AppName.Id.Guid
new-azurermroleassignment -ObjectId $AppObjectID -RoleDefinitionName "Reader" -Scope "/subscriptions/$subscriptionid"
new-azurermroleassignment -ObjectId $AppObjectID -RoleDefinitionName "Reader and Data Access" -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname"
##END SCRIPT
