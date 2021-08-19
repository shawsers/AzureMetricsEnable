<#
.VERSION
1.2 - Add Turbonomic SPN
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
#START SCRIPT
Write-Host "Starting script..." -ForegroundColor Green

$error.clear()

#Reading subs.txt file
Write-Host "Reading subs.txt input file..." -ForegroundColor Green
$readsubsfile = get-content -path .\subs.txt -ErrorAction SilentlyContinue -InformationAction SilentlyContinue -WarningAction SilentlyContinue
if ($readsubsfile -eq $null) {
    write-host "Input file subs.txt not found or it is empty, please verify and try again, exiting script..." -ForegroundColor Red
    Exit
}

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

#Prompt for custom Turbonomic SPN if needed other than the default of svc-turbonomic
$customspn = read-host -Prompt 'Input your Turbonomic SPN Display Name (press enter for using default of ''svc-turbonomic'')'
if ($customspn -eq "") {
    $turbospnname = 'svc-turbonomic'
} else {
    $turbospnname = $customspn
}

$verifyturbospn = get-azadserviceprincipal | where-object{$_.DisplayName -eq $turbospnname}
if ($verifyturbospn -eq $null) {
    Write-Host "Turbonomic SPN named: ""$turbospnname"" not found, exiting script, please verify and run script again..." -ForegroundColor Red
    Exit
}

$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}

Add-Content -Path .\TurboRoleAddedToSubs_$TimeStamp.csv -Value "Subscription Name,Subscription ID,Role Name"
Add-Content -Path .\TurboRoleAdded_Errors_$TimeStamp.csv -Value "Failed Subscription,Reason"
$subcount = 0
$errorcount = 0
$successcount = 0
$subcount = ($readsubsfile).count
$counter = 0
foreach ($azuresub in $readsubsfile){
    $counter ++
    Write-Host "Starting Subscription named: ""$azuresub"" which is Sub number $counter of $subcount"
    $selectSub = Select-AzSubscription -Subscriptionname $azuresub -ErrorAction SilentlyContinue -InformationAction SilentlyContinue -WarningAction SilentlyContinue | set-azcontext
    $subscriptionId = $selectSub.subscription.Id
    $subname = $selectSub.subscription.name
    if ($subname -eq $null) {
        Write-Host "Subscription not found: ""$azuresub"" skipping, please verify and update Sub name in input file and try again" -ForegroundColor Red
        Add-Content -Path .\TurboRoleAdded_Errors_$TimeStamp.csv -Value "$azuresub,Subscription Name not found or invalid"
        $errorcount ++
    } else {
        $date = date
        $checkturbospn = get-azroleassignment | where-object{$_.DisplayName -eq $turbospnname} | where-object{$_.RoleDefinitionName -eq 'Reader'}
        if ($checkturbospn -eq $null){
            $turbospn = get-azadserviceprincipal | where-object{$_.DisplayName -eq $turbospnname}
            $turbospnid = $turbospn.Id
            Write-Host "Assinging Turbonomic SPN Reader permission to Sub: $subname" -ForegroundColor Green
            $assignturbospn = new-azroleassignment -ObjectId $turbospnid -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            Add-Content -Path .\TurboRoleAddedToSubs_$TimeStamp.csv -Value "$subname,$subscriptionId,Reader"
            $successcount ++
        } else {
            Write-Host "Turbonomic SPN already has Reader role assigned on Sub: $subname skipping" -ForegroundColor Green
        } 
    }    
    $error.clear()
    Write-Host " "
}
$date = date
Write-Host "**Script completed at $date" -ForegroundColor Green
Write-Host " "
if ($errorcount -gt 0) {
    Write-Host "**Check error output file for failed subs and details: TurboRoleAdded_Errors_$TimeStamp.csv" -ForegroundColor Red
}
if ($successcount -gt 0) {
    Write-Host "**Check output file for successful subs: TurboRoleAddedToSubs_$TimeStamp.csv for the logs" -ForegroundColor Green
}
#END SCRIPT