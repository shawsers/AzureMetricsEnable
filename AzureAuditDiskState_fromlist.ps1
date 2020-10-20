#Audit Azure disk state from input file
#Created by: Jason.Shaw@turbonomic.com
#Updated: Oct. 20, 2020

#Input file name needs to be in the same directory you are running the file from
#Input file name needs to be disklist.csv

#START SCRIPT
$starttime = date
$date = get-date -Format m
$month = $date.replace(" ","_")

#Read Input file
$eudisks = Import-Csv .\disklist.csv

#Create output file
add-content -path .\Disk_State_$month.csv -value "SUB NAME,RG NAME,DISK NAME,DISK SIZE GB,DISK STATE,DISK ID"
foreach ($disk in $eudisks){
    $sub = $disk.TARGET
    $rgname = $disk.RGNAME
    $diskname = $disk.DISKNAME
    $login = Get-AzSubscription -Subscriptionname $sub | set-azcontext
    if ($login -eq $null){
        write-host "No access to sub id: $sub skipping...." -ForegroundColor Red
        add-content -path .\Disk_State_$month.csv -value "$sub,$rgname,$diskname,NO ACCESS TO THE SUB,NO ACCESS TO THE SUB,NO ACCESS TO THE SUB"
    } else {
        $subname = $login.subscription.name
        $getdisk = get-azdisk -resourcegroupname $rgname -diskname $diskname -ErrorAction SilentlyContinue
        if ($getdisk -eq $null){
	    $getdisknorg = get-azdisk | where {$_.Name -eq $diskname}
            if ($getdisknorg -eq $null){
            	write-host "Disk: $diskname in sub: $subname does not exist, skipping..." -ForegroundColor Red
            	add-content -path .\Disk_State_$month.csv -value "$subname,$rgname,$diskname,DISK DOES NOT EXIST,DISK DOES NOT EXIST,DISK DOES NOT EXIST"
	    } else {
		Write-host "Disk: $diskname found in sub: $subname getting disk info..." -ForegroundColor Green
            	$dstate = $getdisknorg.diskstate
            	$dsize = $getdisknorg.disksizegb
            	$did = $getdisknorg.id
		$drg = $getdisknorg.resourcegroupname
            	add-content -path .\Disk_State_$month.csv -value "$subname,$drg,$diskname,$dsize,$dstate,$did"
	    }
        } else {
            Write-host "Disk: $diskname found in sub: $subname getting disk info..." -ForegroundColor Green
            $dstate = $getdisk.diskstate
            $dsize = $getdisk.disksizegb
            $did = $getdisk.id
            add-content -path .\Disk_State_$month.csv -value "$subname,$rgname,$diskname,$dsize,$dstate,$did"
        }
    }
}
$endtime = date
write-host "script started: $starttime" -ForegroundColor Green
write-host "script ended: $endtime" -ForegroundColor Green
write-host "check output file: Disk_State_$month.csv"
#END SCRIPT
