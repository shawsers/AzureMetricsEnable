###install-module azuread
connect-azuread
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
$myApp = New-AzureADApplication -DisplayName Turbonomic -IdentifierUris 2 -RequiredResourceAccess @($reqGraph, $reqGraph2)
###AppID
$appid = $myApp.appid
$mySecret = New-AzureADApplicationPasswordCredential -ObjectId $myapp.ObjectId -enddate 7/20/2980 -CustomKeyIdentifier "Turbonomic"
$myspn = New-AzureADServicePrincipal -AccountEnabled $true -AppId $MyApp.AppId -AppRoleAssignmentRequired $true -DisplayName Turbonomic
$sub = get-azurermsubscription
$subname = $sub.name
$tenantid = $sub.TenantId
Add-Content -Path .\TurboAppInfo.csv = "Subscription Name,Applicaton ID,Application Secret Key,Tenant ID"
Add-Content -Path .\TurboAppInfo.csv = $subname,$appid,$mySecret,$tenantid