<#
.VERSION
1.6 - All Turbonomic SPNs
Updated Date: Nov. 20, 2019 - 6:05PM
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

#This will remove the SPNs roles and scope of the subscription and the existing Turbonomic storage account(s)
#You need to specify a list of the subscription names in a text file
#Make sure to update the get-content file path below with the path to your actual file
#this script will remove Subscriptions listed in the subs-remove.txt file listed in the script below.
#make sure that the .txt file is in the same directory as the script is when it is run.

#You also have to specify an environment parameter now which you have to input one of the following
#PROD - which will apply the role and scope for PROD US
#PROD2 - which will apply the role and scope for PROD US 2
#PRODEU - which will apply the role and scope for PROD EU
#STAGE - which will apply the role and scope for Stage1
#STAGE2 - which will apply the role and scope for Stage2
#STAGE3 - which will apply the role and scope for Stage3
#DEV - which will apply the role and scope for Dev

#example: .\AzureRemoveSPNRole.ps1 -environment STAGE
#>
param(
 [Parameter(Mandatory=$True)]
 [string] $environment
)
 write-host "starting the script" -ForegroundColor Green
 write-host "reading input file..." -ForegroundColor Green
 $subsremove = get-content -path .\subs-remove.txt
 $error.clear()
 $TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
 #Login Azure Account
 connect-azurermaccount -ErrorAction Stop
 #add logging
 Add-Content -Path .\RemovedAzureRoles.csv -Value "Sub Name,Sub ID,SPN Name,Storage Path Scope,Errors, SPN Role after Chanage, SPN Scope after Change"
 foreach ($azuresub in $subsremove){
     $error.clear()
     $selectSub = Select-AzureRmSubscription -SubscriptionName $azuresub -InformationAction SilentlyContinue
     $subid = $selectSub.subscription.Id
     $sub = $azuresub
     write-host "starting Sub named ""$sub"" now" -ForegroundColor Green
     #Find Turbonomic RG and Storage
     Write-Host "checking Turbo resource groups" -ForegroundColor Green
     $storageAll = get-azurermresourcegroup | where {$_.ResourceGroupName -like '*turbo*'}
     foreach ($rsg in $storageAll){
        $resourceGroup = $rsg.ResourceGroupName
        Write-Host "checking Turbo storage accounts" -ForegroundColor Green
        $storageTurboName = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup | where {$_.StorageAccountName -like '*turbo*'}
     foreach ($turbostor in $storageTurboName){
        $storageaccountname = $turbostor.StorageAccountName
        $storpath = $turbostor.Id.Guid
        $error.clear()
        if ($environment -eq "PROD"){
            $turboSPNprodus1 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'turbonomic'}
            $spnid = $turboSPNprodus1.Id.Guid
            $spn = $turboSPNprodus1.DisplayName
            write-host "removing SPN named ""$spn"" from Sub named ""$sub"" Turbo storage account then waiting for Azure AD to update" -ForegroundColor Green
            Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName "Turbonomic Operator ReadOnly" -Scope "/subscriptions/$subid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            sleep 30
            write-host "removing SPN named ""$spn"" from Sub named ""$sub"" then waiting for Azure AD to update" -ForegroundColor Green
            Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName Reader -Scope "/subscriptions/$subid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            sleep 60
            write-host "starting validation part of the script now..." -ForegroundColor Green
            $turbo = get-azurermroleassignment | where-object{$_.DisplayName -eq $spn}
            $turborole = $turbo.RoleDefinitionName
            $turboscope = $turbo.Scope
            write-host "done this sub.....writing output to log file now" -ForegroundColor Green
            Add-Content -Path .\RemovedAzureRoles.csv -Value "$sub,$subid,$spn,$storpath,$error,$turborole,$turboscope"
            $error.clear()
            }
        if ($environment -eq "PRODEU"){
            $turboSPNprodeu = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-EU'}
            $spnid = $turboSPNprodeu.Id.Guid
            $spn = $turboSPNprodeu.DisplayName
            write-host "removing SPN named ""$spn"" from Sub named ""$sub"" Turbo storage account then waiting for Azure AD to update" -ForegroundColor Green
            Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName "Turbonomic Operator ReadOnly" -Scope "/subscriptions/$subid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            sleep 30
            write-host "removing SPN named ""$spn"" from Sub named ""$sub"" then waiting for Azure AD to update" -ForegroundColor Green
            Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName Reader -Scope "/subscriptions/$subid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            sleep 60
            write-host "starting validation part of the script now..." -ForegroundColor Green
            $turbo = get-azurermroleassignment | where-object{$_.DisplayName -eq $spn}
            $turborole = $turbo.RoleDefinitionName
            $turboscope = $turbo.Scope
            write-host "done this sub.....writing output to log file now" -ForegroundColor Green
            Add-Content -Path .\RemovedAzureRoles.csv -Value "$sub,$subid,$spn,$storpath,$error,$turborole,$turboscope"
            $error.clear()
            }
        if ($environment -eq "PROD2"){
            $turboSPNprodus2 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-US-2'}
            $spnid = $turboSPNprodus2.Id.Guid
            $spn = $turboSPNprodus2.DisplayName
            write-host "removing SPN named ""$spn"" from Sub named ""$sub"" Turbo storage account then waiting for Azure AD to update" -ForegroundColor Green
            Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName "Turbonomic Operator ReadOnly" -Scope "/subscriptions/$subid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            sleep 30
            write-host "removing SPN named ""$spn"" from Sub named ""$sub"" then waiting for Azure AD to update" -ForegroundColor Green
            Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName Reader -Scope "/subscriptions/$subid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            sleep 60
            write-host "starting validation part of the script now..." -ForegroundColor Green
            $turbo = get-azurermroleassignment | where-object{$_.DisplayName -eq $spn}
            $turborole = $turbo.RoleDefinitionName
            $turboscope = $turbo.Scope
            write-host "done this sub.....writing output to log file now" -ForegroundColor Green
            Add-Content -Path .\RemovedAzureRoles.csv -Value "$sub,$subid,$spn,$storpath,$error,$turborole,$turboscope"
            $error.clear()
            }
        if ($environment -eq "STAGE"){
                $turboSPNstage1 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-Stage'}
                $subid = $turboSPNstage1.Id.Guid
                $spn = $turboSPNstage1.DisplayName
                write-host "removing SPN named ""$spn"" from Sub named ""$sub"" Turbo storage account then waiting for Azure AD to update" -ForegroundColor Green
                Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName "Turbonomic Operator ReadOnly" -Scope "/subscriptions/$subid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                sleep 30
                write-host "removing SPN named ""$spn"" from Sub named ""$sub"" then waiting for Azure AD to update" -ForegroundColor Green
                Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName Reader -Scope "/subscriptions/$subid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                sleep 60
                write-host "starting validation part of the script now..." -ForegroundColor Green
                $turbo = get-azurermroleassignment | where-object{$_.DisplayName -eq $spn}
                $turborole = $turbo.RoleDefinitionName
                $turboscope = $turbo.Scope
                write-host "done this sub.....writing output to log file now" -ForegroundColor Green
                Add-Content -Path .\RemovedAzureRoles.csv -Value "$sub,$subid,$spn,$storpath,$error,$turborole,$turboscope"
                $error.clear()
                }
        if ($environment -eq "STAGE2"){
                $turboSPNstage2 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Stage2'}
                $spnid = $turboSPNstage2.Id.Guid
                $spn = $turboSPNstage2.DisplayName
                write-host "removing SPN named ""$spn"" from Sub named ""$sub"" Turbo storage account then waiting for Azure AD to update" -ForegroundColor Green
                Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName "Turbonomic Operator ReadOnly" -Scope "/subscriptions/$subid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                sleep 30
                write-host "removing SPN named ""$spn"" from Sub named ""$sub"" then waiting for Azure AD to update" -ForegroundColor Green
                Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName Reader -Scope "/subscriptions/$subid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                sleep 60
                write-host "starting validation part of the script now..." -ForegroundColor Green
                $turbo = get-azurermroleassignment | where-object{$_.DisplayName -eq $spn}
                $turborole = $turbo.RoleDefinitionName
                $turboscope = $turbo.Scope
                write-host "done this sub.....writing output to log file now" -ForegroundColor Green
                Add-Content -Path .\RemovedAzureRoles.csv -Value "$sub,$subid,$spn,$storpath,$error,$turborole,$turboscope"
                $error.clear()
                }
        if ($environment -eq "STAGE3"){
                $turboSPNstage3 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Stage3'}
                $spnid = $turboSPNstage3.Id.Guid
                $spn = $turboSPNstage3.DisplayName
                write-host "removing SPN named ""$spn"" from Sub named ""$sub"" Turbo storage account then waiting for Azure AD to update" -ForegroundColor Green
                Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName "Turbonomic Operator ReadOnly" -Scope "/subscriptions/$subid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                sleep 30
                write-host "removing SPN named ""$spn"" from Sub named ""$sub"" then waiting for Azure AD to update" -ForegroundColor Green
                Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName Reader -Scope "/subscriptions/$subid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                sleep 60
                write-host "starting validation part of the script now..." -ForegroundColor Green
                $turbo = get-azurermroleassignment | where-object{$_.DisplayName -eq $spn}
                $turborole = $turbo.RoleDefinitionName
                $turboscope = $turbo.Scope
                write-host "done this sub.....writing output to log file now" -ForegroundColor Green
                Add-Content -Path .\RemovedAzureRoles.csv -Value "$sub,$subid,$spn,$storpath,$error,$turborole,$turboscope"
                $error.clear()
                }
        if ($environment -eq "DEV"){
            $turboSPNdev = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic_Dev'}
            $spnid = $turboSPNdev.Id.Guid
            $spn = $turboSPNdev.DisplayName
            write-host "removing SPN named ""$spn"" from Sub named ""$sub"" Turbo storage account then waiting for Azure AD to update" -ForegroundColor Green
            Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName "Turbonomic Operator ReadOnly" -Scope "/subscriptions/$subid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            sleep 30
            write-host "removing SPN named ""$spn"" from Sub named ""$sub"" then waiting for Azure AD to update" -ForegroundColor Green
            Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName Reader -Scope "/subscriptions/$subid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            sleep 60
            write-host "starting validation part of the script now..." -ForegroundColor Green
            $turbo = get-azurermroleassignment | where-object{$_.DisplayName -eq $spn}
            $turborole = $turbo.RoleDefinitionName
            $turboscope = $turbo.Scope
            write-host "done this sub.....writing output to log file now" -ForegroundColor Green
            Add-Content -Path .\RemovedAzureRoles.csv -Value "$sub,$subid,$spn,$storpath,$error,$turborole,$turboscope"
            $error.clear()
        }
     }
    }
 }
 write-host "script is done please review the log files named RemovedAzureRoles.csv in the current working directory" -ForegroundColor Green
 write-host "**SCRIPT IS DONE NOW**" -ForegroundColor Green 
 #End of script
