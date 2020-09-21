#This script will connect to all of the Azure subscriptions you have access to and report on all unattached disks

#START SCRIPT
$starttime = date
$date = get-date -Format m
$month = $date.replace(" ","_")

#Check if Azure AZ PowerShell cmdlet is installed
$azurecmdlets = Get-InstalledModule -Name az
if ($azurecmdlets -eq $null){
    Write-Host "Azure AZ module not found, installing.....this can take a few mins to complete...." -ForegroundColor Green
    Install-Module -name az -scope CurrentUser
    Write-Host "Azure AZ module installed, checking..." -ForegroundColor Green
    $azuremodver = get-installedmodule -Name az -MinimumVersion 3.5.0 -ErrorAction SilentlyContinue
    if ($azuremodver -eq $null){
        Write-Host "Azure AZ module not installed, quitting script..." -ForegroundColor Red
        Write-Host "**Please manually install Azure AZ module or try running the script again**" -ForegroundColor Red
        Exit
        #Script exits if the Azure AZ cmdlet not installed as it is required to continue the script
    }
} else {
    $azuremodver = get-installedmodule -Name az -MinimumVersion 3.5.0 -ErrorAction SilentlyContinue
    if ($azuremodver -eq $null){
        Write-Host "Azure AZ module out of date, updating.....this can take a few mins to complete...." -ForegroundColor Green
        #If out of date Azure AZ cmdlet found, it will attempt to update it to the current verison
        Update-Module -Name az -Force
        Write-Host "Azure AZ module updated, continuing..." -ForegroundColor Green
    }
}

#If Azure AZ cmdlet installed then continue to get sub list and report
$subs = get-azsubscription
add-content -path .\All_Unattached_Disks_$month.csv -value "SUB NAME,RG NAME,DISK NAME,DISK SIZE GB,DISK STATE,DISK ID"
foreach ($disk in $subs){
    $subid = $disk.id
    $subn = $disk.name
    $login = Get-AzSubscription -Subscriptionid $subid | set-azcontext
    $substate = $login.state
    if ($substate -ne "Enabled" -or $login -eq $null){
        write-host "Sub: $subn is not enabled or no access, skipping...." -ForegroundColor Red
        add-content -path .\All_Unattached_Disks_$month.csv -value "$subn,SUB IS NOT ENABLED,SUB IS NOT ENABLED,SUB IS NOT ENABLED,SUB IS NOT ENABLED,SUB IS NOT ENABLED"
    } else {
        $subname = $login.subscription.name
        #$getdisks = get-azdisk | where {$_.diskstate -eq "Unattached"}
        $getdisks = get-azdisk | where-object -Property diskstate -eq unattached
        if ($getdisks -eq $null){
            write-host "No unattached disk in sub: $subname skipping..." -ForegroundColor Red
            add-content -path .\All_Unattached_Disks_$month.csv -value "$subname,$rgname,NO UNATTACHED DISKS,NO UNATTACHED DISKS,NO UNATTACHED DIKS,NO UNATTACHED DISKS"
        } else {
            Write-host "Unattached disks found in sub: $subname getting disk info..." -ForegroundColor Green
            foreach ($getdisk in $getdisks){
            $dstate = $getdisk.diskstate
            $dsize = $getdisk.disksizegb
            $did = $getdisk.id
            $rgname = $getdisk.resourcegroupname
            $diskname = $getdisk.name
            add-content -path .\All_Unattached_Disks_$month.csv -value "$subname,$rgname,$diskname,$dsize,$dstate,$did"
            }
        }
    }
}
$endtime = date
write-host "script started: $starttime" -ForegroundColor Green
write-host "script ended: $endtime" -ForegroundColor Green
write-host "check output file: All_Unattached_Disks_$month.csv"
#END SCRIPT