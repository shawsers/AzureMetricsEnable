##This script will create the Turbonomic App Registration in Azure Active Directory
##The script will then assign the delegated permissions required for Turbonomic
##Example: .\AzureCreateTurboAppReg.ps1 -subscriptionid SUB-ID-HERE -turboappname NAME-OF-TURBO-APP

param(

 [Parameter(Mandatory=$True)]
 [string]
 $subscriptionId,

 [Parameter(Mandatory=$True)]
 [string]
 $TurboAppName
)

Login-AzureRmAccount -subscriptionid $subscriptionId
$svcprincipal = Get-AzureADServicePrincipal -All $true | ? { $_.DisplayName -match "Microsoft Graph" }
$svcprincipal2 = Get-AzureADServicePrincipal -All $true | ? { $_.DisplayName -match "Windows Azure Service Management API" }
### Microsoft Graph
$reqGraph = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$reqGraph.ResourceAppId = $svcprincipal.AppId
###Windows Azure Service Management API
$reqGraph2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
$reqGraph2.ResourceAppId = $svcprincipal2.AppId
$permission = $svcprincipal.Oauth2Permissions | ? { $_.Value -eq "User.Read" }
$permission2 = $svcprincipal2.Oauth2Permissions | ? { $_.Value -eq "user_impersonation" }
$appPermission1 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "e1fe6dd8-ba31-4d61-89e7-88639da4683d","Scope"
$appPermission2 = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess" -ArgumentList "41094075-9dad-400e-a0bd-54e686782033","Scope"
$reqGraph.ResourceAccess = $appPermission1
$reqGraph2.ResourceAccess = $appPermission2
$myApp = New-AzureADApplication -DisplayName $TurboAppName -IdentifierUris 99 -RequiredResourceAccess @($reqGraph, $reqGraph2)
###AppID
$appid = $myApp.appid
$mySecret = New-AzureADApplicationPasswordCredential -ObjectId $myapp.ObjectId -enddate 7/20/2980 -CustomKeyIdentifier $TurboAppName
$myspn = New-AzureADServicePrincipal -AccountEnabled $true -AppId $MyApp.AppId -AppRoleAssignmentRequired $true -DisplayName $TurboAppName
$sub = get-azurermsubscription
$subname = $sub.name
$tenantid = $sub.TenantId
$mySecretkey = $mySecret.Value
Add-Content -Path .\TurboAppInfo.csv -Value "Subscription Name,Applicaton ID,Application Secret Key,Tenant ID"
Add-Content -Path .\TurboAppInfo.csv -Value "$subname,$appid,$mySecretkey,$tenantid"