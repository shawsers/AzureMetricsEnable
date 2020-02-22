#START SCRIPT
#Make sure to create a file named sub-ids.txt and add all of the sub names to it you want to run the script on
$login = login-azureazaccount -ErrorAction Stop
$date = date
Write-Host "Script started at: $date"
Write-Host "Reading input file"
$subs = Get-Content -Path .\sub-ids.txt
Add-Content -Path .\subid-subnames.csv -Value "Sub ID,Sub Name"
foreach ($sub in $subs){
    $selectsub = Select-AzSubscription -Subscription $sub
    $subname = $selectsub.Subscription.Name
    $subid = $selectsub.Subscription.SubscriptionId
    Add-Content -Path .\subid-subnames.csv -Value "$subid,$subname"
}
Write-host "Script is complete please review output file subid-subnames.csv"
#END SCRIPT
