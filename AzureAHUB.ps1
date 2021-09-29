#This script will report on all Windows VM's in all Azure Subs you have access to and their AHUB status
#The script doesn't currently list the license cost, that you will have to manually review using the Azure Price Calculator
#START SCRIPT
$starttime = date
$date = get-date -Format m
$month = $date.replace(" ","_")

login-azaccount -ErrorAction Stop
add-content -Path .\AHUB_Status_$month.csv -value "Sub Name,RG Name,VM Name,VM Size,VM OS Type,AHUB Status,VM Owner"
$azuresub = get-azsubscription
foreach ($sub in $azuresub){
    $subid = $sub.id
    $subname = $sub.Name
    write-host "Starting Sub: $subname" -ForegroundColor Green
    $login = Get-AzSubscription -Subscriptionid $subid | set-azcontext
    $winvms = get-azvm | where {$_.StorageProfile.OsDisk.OsType -eq "Windows"}
    foreach ($winvm in $winvms){
        $ahub = $winvm.LicenseType
        $offer = $winvm.StorageProfile.ImageReference.Offer
        $vmname = $winvm.Name
        $rgname = $winvm.ResourceGroupName
        $vmsize = $winvm.HardwareProfile.VmSize
        $tags = (Get-AzResourceGroup -Name $rgname).tags
        $owner = $tags["ghs-owner"]
        if ($owner -eq $null) {
            $tags = (get-azvm -ResourceGroupName $rgname -Name $vmname).tags
            $owner = $tags["ghs-owner"]
            }
        write-host "Starting Windows VM named: $vmname in Sub: $subname" -ForegroundColor Green
        add-content -path .\AHUB_Status_$month.csv -value "$subname,$rgname,$vmname,$vmsize,$offer,$ahub,$owner"
        }
    }
$endtime = date
write-host "script started: $starttime" -ForegroundColor Green
write-host "script ended: $endtime" -ForegroundColor Green
write-host "check output file: AHUB_Status_$month.csv"
#END SCRIPT