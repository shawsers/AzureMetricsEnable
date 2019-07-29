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
$permission2 = $svcprincipal2.Oauth2Permissions | ? { $_.Value -eq "user_impersonation" }
$appPermission1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "e1fe6dd8-ba31-4d61-89e7-88639da4683d","Scope"
$appPermission2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "41094075-9dad-400e-a0bd-54e686782033","Scope"
$reqGraph.ResourceAccess = $appPermission1
$reqGraph2.ResourceAccess = $appPermission2

#Create Turbonomic App Registration with delegations
$myApp = New-AzureADApplication -DisplayName $TurboAppName -IdentifierUris $TurboAppName -RequiredResourceAccess @($reqGraph, $reqGraph2)
$myspn = New-AzureADServicePrincipal -AccountEnabled $true -AppId $MyApp.AppId -AppRoleAssignmentRequired $true -DisplayName $TurboAppName

#Create Turbonomic App Secret Key
$mySecret = New-AzureADApplicationPasswordCredential -ObjectId $myapp.ObjectId -enddate 7/20/2980 -CustomKeyIdentifier $TurboAppName

#Create log file for output of info needed to register Azure information in Turbonomic UI
$appid = $myApp.appid
$subget = get-azurermsubscription
$subname = $subget.name
$mySecretkey = $mySecret.Value
Add-Content -Path .\TurboAppInfo.csv -Value "Subscription Name,Subscription ID,Application Name,Applicaton ID,Application Secret Key,Tenant ID,Resource Group,Storage Account"
Add-Content -Path .\TurboAppInfo.csv -Value "$subname,$subscriptionId,$TurboAppName,$appid,$mySecretkey,$tenantid,$resourcegroup,$storageaccountname"
#Assign Turbonomic App Registration Read Only access to the subscription
$AppName = Get-AzureADServicePrincipal -All $true | ? { $_.DisplayName -match $TurboAppName }
$AppObjectID = $AppName.ObjectId
new-azurermroleassignment -ObjectId $AppObjectID -RoleDefinitionName "Reader" -Scope "/subscriptions/$subscriptionid"
##END SCRIPT