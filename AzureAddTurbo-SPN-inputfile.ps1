<#
.VERSION
1.1 - Add Turbonomic SPN
Updated Date: Aug. 17, 2021
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

This script will add the Turbonomic SPN named 'svc-turbonomic' to the Azure subs specified, 
in the subs.txt file that you have Owner access to.

If you are using a different SPN name you need to change it in the $turbospnname variable below

Make sure the subs.txt file exists in the same directory as the script,
and has the list of sub names you want to run the script against, 
each sub name needs to be on a separate line in the file.

example of how to run the script: .\AzureAddTurbo-SPN-inputfile.ps1

Script will work in Azure Cloud Shell and from your system,
as long as it already has the Azure az cmdlets installed.
#>
$turbospnname = 'svc-turbonomic' 
$error.clear()

#Checking if the script is running from Azure Cloud Shell or not
write-host "Checking if running script in Azure Cloud Shell...." -ForegroundColor Blue
if (($host.name) -eq 'ConsoleHost'){
    write-host "Azure Cloud Shell in use, continuing...." -ForegroundColor Green
    $cloudshell = $True
  } else {
    write-host "checking if Azure Az cmdlet is installed, if not it will install/update it as needed" -ForegroundColor Blue
    $azurecmdlets = Get-InstalledModule -Name Az
    if ($azurecmdlets -eq $null){
        Write-Host "Azure Az module not found, installing.....this can take a few mins to complete...." -ForegroundColor White
        Install-Module -name az -AllowClobber -scope CurrentUser
    } else {
        Write-Host "Azure Az module installed, continuing..." -ForegroundColor Green
    }
    write-host "Not using Azure Cloud Shell, prompting to login to Azure now...." -ForegroundColor Blue
    $logsub = Login-azAccount -ErrorAction Stop
}

$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
#Reading subs.txt file
Write-Host "Reading subs.txt file..." -ForegroundColor Green
$readsubsfile = get-content -path .\subs.txt -ErrorAction Stop
Add-Content -Path .\TurboRoleAddedToSubs_$TimeStamp.csv -Value "Subscription Name,Subscription ID,Role Name"
Add-Content -Path .\TurboRoleAdded_Errors_$TimeStamp.csv -Value "Failed Subscription,Reason"
$errorcount = 0
$subcount = ($readsubsfile).count
$counter = 0
foreach ($azuresub in $readsubsfile){
    $counter ++
    Write-Host "Starting Subscription name: $azuresub which is Sub number $counter of $subcount"
    $selectSub = Select-AzSubscription -Subscriptionname $azuresub -InformationAction SilentlyContinue | set-azcontext
    $subscriptionId = $selectSub.subscription.Id
    $subname = $selectSub.subscription.name
    if ($subname -eq $null) {
        Write-Host "Subscription not found: ""$azuresub"" skipping, please verify and update Sub name in input file and try again" -ForegroundColor Red
        Add-Content -Path .\TurboRoleAdded_Errors_$TimeStamp.csv -Value "$azuresub,Subscription Name not found or invalid"
    } else {
        $date = date
        Write-Host "**Script started for Sub: $subname at $date" -ForegroundColor Green
        $checkturbospn = get-azroleassignment | where-object{$_.DisplayName -eq $turbospnname} | where-object{$_.RoleDefinitionName -eq 'Reader'}
        if ($checkturbospn -eq $null){
            $turbospn = get-azadserviceprincipal | where-object{$_.DisplayName -eq $turbospnname}
            $turbospnid = $turbospn.Id
            Write-Host "Assinging Turbonomic SPN Reader permission to Sub: $subname" -ForegroundColor Green
            $assignturbospn = new-azroleassignment -ObjectId $turbospnid -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            Add-Content -Path .\TurboRoleAddedToSubs_$TimeStamp.csv -Value "$subname,$subscriptionId,Reader"
        } else {
            Write-Host "Turbonomic SPN already has Reader role assigned on Sub: $subname skipping"
        } 
    }    
    $error.clear()
    $subcount ++      
}
$date = date
Write-Host "**Script completed at $date" -ForegroundColor Green
Write-Host "**Check output file for successful subs: TurboRoleAddedToSubs_$TimeStamp.csv for the logs" -ForegroundColor Green
Write-Host "**Check error output file for failed subs: TurboRoleAdded_Errors_$TimeStamp.csv if any" -ForegroundColor Red
#END SCRIPT