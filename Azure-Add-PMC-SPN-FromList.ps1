<#
.VERSION
1.0 - Add Turbonomic ParkMyCloud (PMC) SPN
Updated Date: July 9, 2020
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

#This script will add the Turbonomic PMC SPN as Reader to the Azure subs in the subs.txt input file

#Make sure the subs.txt file exists and has the list of subs you want to run the script against in it
#example: .\Azure-Add-PMC-SPN-FromList.ps1
#>
$logsub = Login-AzureRmAccount -ErrorAction Stop -InformationAction SilentlyContinue
$error.clear()
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
Add-Content -Path .\TurboPMCRoleAddedToSubs.csv -Value "SUB NAME,SUB ID,SPN NAME"
$readsubsfile = get-content -path .\subs.txt
foreach ($azuresub in $readsubsfile){
    $selectSub = Select-AzureRmSubscription -Subscriptionname $azuresub -InformationAction SilentlyContinue | set-azurermcontext
    $subscriptionId = $selectSub.subscription.Id
    $subname = $selectSub.subscriptionname
    $date = date
    Write-Host "**Script started sub: $subname at $date" -ForegroundColor Green
                $turboSPNprodus1 = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq 'Turbonomic-PMC'}
                $turboSPNprodus1id = $turboSPNprodus1.Id.Guid
                Write-Host "Assinging Turbonomic PMC SPN Reader permission on sub: $subname" -ForegroundColor Green
                $assignReaderProd = new-azurermroleassignment -ObjectId $turboSPNprodus1id -RoleDefinitionName Reader -Scope "/subscriptions/$subscriptionid" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                Add-Content -Path .\TurboPMCRoleAddedToSubs.csv -Value "$subname,$subscriptionId,Turbonomic-PMC"
}
$date = date
Write-Host "**Script completed at $date" -ForegroundColor Green
Write-Host "**Check file name: TurboPMCRoleAddedToSubs.csv for the logs" -ForegroundColor Green
#END SCRIPT
