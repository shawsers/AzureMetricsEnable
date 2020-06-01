#START SCRIPT
$starttime = date
$date = get-date -Format m
$month = $date.replace(" ","_")
$eudisks = get-azsubscription
add-content -path .\All_Unattached_Disks_$month.csv -value "SUB NAME,RG NAME,DISK NAME,DISK SIZE GB,DISK STATE,DISK ID"
foreach ($disk in $eudisks){
    $subid = $disk.id
    $login = Get-AzSubscription -Subscriptionid $subid | set-azcontext
    if ($login -eq $null){
        write-host "No access to sub id: $sub skipping...." -ForegroundColor Red
        add-content -path .\All_Unattached_Disks_$month.csv -value "$sub,$rgname,$diskname,NO ACCESS TO THE SUB,NO ACCESS TO THE SUB,NO ACCESS TO THE SUB"
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
