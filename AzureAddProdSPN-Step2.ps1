<#
.VERSION
3.0 - All Turbonomic Prod SPNs
Updated Date: Jan. 16, 2019 - 2:20PM
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

#This script will add the Prod SPN's to the Azure sub
#This script assumes that you have already run the Step1 script which is to create the required RG and Storage account and assign the Dev and Stage SPN's to them.
#This script also assumes you have an RG and Storage account already created both with "turbo" in the name of them.

Make sure to create a file named subs-prod.txt and that it is in the directory you are running the script from.  It needs to contain a list of sub names to read in and run the script against

#You also have to specify an environment parameter now which you have to input one of the following
#PROD1 - which will apply the role and scope for PROD US
#PROD2 - which will apply the role and scope for PROD US 2
#PRODEU - which will apply the role and scope for PROD EU

#Make sure the sub in the parameter below is one that has already been onboarded
#example: .\AzureCreateStorageAccount.ps1 -subid SUB-ID-HERE -environment PROD1
#example: .\AzureCreateStorageAccount.ps1 -subid 82cdab36-1a2a-123a-1234-f9e83f17944b -environment PROD1
#>

param(
 [Parameter(Mandatory=$True)]
 [string] $subId,

 [Parameter(Mandatory=$True)]
 [string] $environment
)
$error.clear()
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
$readsubsfile = get-content -path .\subs-prod.txt
if($subId){
    $logsub = Login-AzureRmAccount -SubscriptionId $subId -ErrorAction Stop
    }
foreach ($azuresub in $readsubsfile){
    $selectSub = Select-AzureRmSubscription -SubscriptionName $azuresub -InformationAction SilentlyContinue
    $subscriptionId = $selectSub.subscription.Id
    $subname = $azuresub
    $date = date
    Write-Host "**Script started at $date" -ForegroundColor Green
    if((Test-Path -Path .\$subname) -ne 'True'){
        Write-Host "Creating new sub directory for log files" -ForegroundColor Green
        $path = new-item -Path . -ItemType "directory" -Name $subname -InformationAction SilentlyContinue -ErrorAction Stop
        $fullPath = $path.FullName
    } else {
        Write-Host "Using existing directory for logs" -ForegroundColor Green
        $path = Get-Location
        $fullPath = $path.Path + "\" + $subname 
    }
    $storageAll = get-azurermresourcegroup | where {$_.ResourceGroupName -like '*turbo*'}
    if ($storageAll -eq $null){
        Write-Host "No Turbonomic RG found in $subname ....exiting script" -ForegroundColor Red -BackgroundColor Black
        Exit
    }
    foreach ($turborg in $storageAll){
        $resourceGroup = $turborg.ResourceGroupName
        $storageTurboName = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup | where {$_.StorageAccountName -like '*turbo*'}
        if ($storageTurboName -eq $null){
            Write-Host "No Turbonomic Storage Account found in $subname ....exiting script" -ForegroundColor Red -BackgroundColor Black
            Exit
        }
        #look at adding error checking for no Turbo storage account found
        foreach ($turbostor in $storageTurboName){
            $storageaccountname = $turbostor.StorageAccountName
            $error.clear()
            $turboCustomRoleName = "Reader and Data Access"
            $selectSub = Select-AzureRmSubscription -Subscription $subscriptionId
            if ($environment -eq "PROD1"){
                $turboSPNprodus1 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'turbonomic'}
                $turboSPNprodus1id = $turboSPNprodus1.Id.Guid
                Write-Host "Assinging Turbonomic PROD 1 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodus1id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodus1id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }
            if ($environment -eq "PRODEU"){
                $turboSPNprodeu = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-EU'}
                $turboSPNprodeuid = $turboSPNprodeu.Id.Guid
                Write-Host "Assinging Turbonomic PROD EU SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodeuid -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodeuid -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }
            if ($environment -eq "PROD2"){
                $turboSPNprodus2 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-US-2'}
                $turboSPNprodus2id = $turboSPNprodus2.Id.Guid
                Write-Host "Assinging Turbonomic PROD 2 SPN App Reg permissions on subscription and storage" -ForegroundColor Green
                $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodus2id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $assignCustomProd = new-azurermroleassignment -ObjectId $turboSPNprodus2id -RoleDefinitionName $turboCustomRoleName -Scope "/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageaccountname" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$subname,$subscriptionId,$TurboCustomRoleName,$environment"
                Add-Content -Path .\$subname\TurboRoleAddedToSubScope.csv -Value "$error"
                $error.clear()
                }
        }
    }
$date = date
Write-Host "**Script completed at $date" -ForegroundColor Green
Write-Host "**Check path: ""$fullPath"" for the logs" -ForegroundColor Green
}