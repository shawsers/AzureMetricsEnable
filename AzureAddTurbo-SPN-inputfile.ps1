<#
.VERSION
1.0 - Add Turbonomic SPN
Updated Date: Aug. 16, 2021
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

#This script will add the Turbonomic SPN named svc-turbonomic to the Azure subs specified, 
#in the subs.txt file that you have Owner access to

#Make sure the subs.txt file exists and has the list of sub names only you want, 
#each on a separate line to run the script against in it
#example: .\AzureAddTurbo-SPN-inputfile.ps1
#>
$error.clear()

#Checking if the script is running from Azure Cloud Shell or not
write-host "Checking if running script in Azure Cloud Shell...." -ForegroundColor Blue
if (($host.name) -eq 'ConsoleHost'){
    write-host "Azure Cloud Shell in use, continuing...." -ForegroundColor Green
    $cloudshell = $True
    #continue
  } else {
    write-host "Not using Azure Cloud Shell, prompting to login to Azure now...." -ForegroundColor Blue
    $logsub = Login-azAccount -ErrorAction Stop
  }

$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
#Reading subs.txt file
Write-Host "Reading subs.txt file..." -ForegroundColor Green
$readsubsfile = get-content -path .\subs.txt -ErrorAction Stop
Add-Content -Path .\TurboRoleAddedToSubs_$TimeStamp.csv -Value "Subscription Name,Subscription ID,Role Name"
foreach ($azuresub in $readsubsfile){
    $selectSub = Select-AzSubscription -Subscriptionname $azuresub -InformationAction SilentlyContinue | set-azurermcontext
    $subscriptionId = $selectSub.subscription.Id
    $subname = $azuresub
    $date = date
    Write-Host "**Script started at $date" -ForegroundColor Green
    $turbospn = get-azadserviceprincipal | where-object{$_.DisplayName -eq 'svc-turbonomic'}
    $turbospnid = $turbospn.Id
    Write-Host "Assinging Turbonomic SPN Reader permission to Sub: $subname" -ForegroundColor Green
    $assignturbospn = new-azroleassignment -ObjectId $turbospnid -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
    Add-Content -Path .\TurboRoleAddedToSubs_$TimeStamp.csv -Value "$subname,$subscriptionId,Reader"
    $error.clear()                
}
$date = date
Write-Host "**Script completed at $date" -ForegroundColor Green
Write-Host "**Check output file: TurboRoleAddedToSubs_$TimeStamp.csv for the logs" -ForegroundColor Green
#END SCRIPT