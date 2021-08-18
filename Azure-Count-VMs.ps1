#Start of Script
Login-AzAccount
#Create output file
$date = get-date -format filedatetime
Add-Content -Path .\VM_Count_$date.csv -Value 'Subscription Name, Subscription ID, VM Count, VMs Powered On Count, VM Scale Set VM Count'
#Get only enabled subscriptions
#$subs = Get-AzSubscription | where {$_.state -eq "Enabled"}
$subs = Get-AzSubscription | where { $_.state -eq "Enabled" -and $_.SubscriptionPolicies.SpendingLimit -eq  "Off"  -and $_.SubscriptionPolicies.QuotaId -ne "PayAsYouGo_2014-09-01" -and $_.name -notlike "*pay-as-you-go*"  -and $_.name -notlike "*Visual Studio*" -and $_.name -notlike "*MSDN*" }
$subcount = ($subs).count
$count = 1
foreach ($sub in $subs) {
    $subid = $sub.SubscriptionId
    $subname = $sub.Name
    write-host "starting sub: $subname which is $count out of $subcount"
    Select-azSubscription -SubscriptionId $subid
    #Get all VM's in the sub
    $vmlist = Get-AzVM
    $vmspoweredon = 0
    foreach ($vm in $vmlist) {
        $rg = $vm.ResourceGroupName
        $vmname = $vm.Name
        #Count of all powered on VM's in each subscription
        $vmstate = (Get-AzVM -ResourceGroupName $rg -Name $vmname -Status | where{$_.PowerState -eq 'VM running'}).count
        $vmspoweredon += $vmstate
    }
    #Get count of all VM's in the subscription
    $vmcount = ($vmlist).count
    #Get all VM Scale Sets
    $vmss = get-azvmss
    $vmsscount = 0
    #Get count of all VM's in the VM Scale Sets
    foreach ($vmssvm in $vmss) {
        $vmssrg = $vmssvm.ResourceGroupName
        $vmssname = $vmssvm.Name
        $vmssnum = (get-azvmssvm -resourcegroupname $vmssrg -vmscalesetname $vmssname).count
        $vmsscount += $vmssnum
    }
    Add-Content -Path .\VM_Count_$date.csv -Value "$subname, $subid, $vmcount, $vmspoweredon, $vmsscount"
    $count ++
}
write-host "End of script please review output file: VM_Count_$date.csv"
#End of Script