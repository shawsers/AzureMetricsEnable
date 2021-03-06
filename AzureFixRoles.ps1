<#
.VERSION
1.0 - All Turbonomic SPNs
Updated Date: Jan 22, 2020
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

#This will add the SPNs roles and scope of the subscription and the existing Turbonomic storage account(s)
#You need to specify a correctly formatted CSV file with the "SUBNAME, SPN, FULLPATH"
#Make sure to update the import-csv file path below with the path to your actual file

#example: .\AzureFixRoles.ps1
#>
 #this script will add the SPN's roles and scopes in the subs listed in the path in import-csv provided on 2 lines below
 write-host "starting the script" -ForegroundColor Green
 write-host "reading input file..." -ForegroundColor Green
 $spnsubstorage = Import-Csv .\inputfile.csv
 $error.clear()
 $TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
 #Login Azure Account
 connect-azurermaccount -ErrorAction Stop
 #add logging
 Add-Content -Path .\AddedAzureRoles.csv -Value "Sub Name,Sub ID,SPN Name,Storage Path Scope,Errors, SPN Role after Chanage, SPN Scope after Change"
 foreach ($substorage in $spnsubstorage){
     $error.clear()
     $sub = $substorage.SUBNAME 
     $spn = $substorage.SPN 
     $storpath = $substorage.FULLPATH 
     $selectSub = Select-AzureRmSubscription -Subscription $sub
     $subid = $selectSub.subscription.id
     write-host "starting Sub named ""$sub"" now" -ForegroundColor Green
     $turboSPN = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq $spn}
     $spnid = $turboSPN.Id.Guid
     write-host "adding SPN named ""$spn"" to Sub named ""$sub"" Turbo storage account then waiting for Azure AD to update" -ForegroundColor Green
     New-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName "Turbonomic Operator ReadOnly" -Scope $storpath -ErrorAction SilentlyContinue
     sleep 30
     write-host "adding SPN named ""$spn"" to Sub named ""$sub"" then waiting for Azure AD to update" -ForegroundColor Green
     New-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName Reader -Scope "/subscriptions/$subid" -ErrorAction SilentlyContinue
     sleep 30
     write-host "starting validation part of the script now..." -ForegroundColor Green
     $turbo = get-azurermroleassignment | where-object{$_.DisplayName -eq $spn}
     $turborole = $turbo.RoleDefinitionName
     $turboscope = $turbo.Scope
     write-host "done this sub.....writing output to log file now" -ForegroundColor Green
     Add-Content -Path .\AddedAzureRoles.csv -Value "$sub,$subid,$spn,$storpath,$error,$turborole,$turboscope"
 }
 write-host "script is done please review the log files named RemovedAzureRoles.csv and SPN_Scope_Sub_Role_Audit.csv in the current working directory" -ForegroundColor Green
 #End of script