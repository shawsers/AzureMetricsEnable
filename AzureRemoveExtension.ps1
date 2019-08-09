param(

 [Parameter(Mandatory=$True)]
 [string]
 $subscriptionId

)
Login-AzureRmAccount -SubscriptionId $subscriptionId -ErrorAction Stop
Select-AzureRmSubscription -Subscription $subscriptionId
$getsub = get-azurermsubscription
$subname = $getsub.Name
$TimeStampLog = Get-Date -Format o | foreach {$_ -replace ":", "."}
$vmsRemoveExt = Get-Content -Path .\VMstoRemoveExt.txt
Add-Content -Path .\RemoveExtLog_$TimeStampLog.csv -Value "Subscription Name,VM Name,OS Type,Extension Status,Extension Message"
foreach($vm in $vmsRemoveExt){
    $status=$vm | Get-AzureRmVM -Status $vm.ResourceGroupName
    if ($status.Statuses[1].DisplayStatus -ne "VM running")
    {
        $vmName = $vm.Name
        Write-Output $vmName" is not running. Skipping check"
        $osUnknown = "OS Unknown"
        $osNotRunning = "OS Not Running"
        $osSkipping = "Skipping verification"
        Add-Content -Path .\RemoveExtLog_$TimeStampLog.csv -Value "$subname,$vmName,$osUnknown,$osNotRunning,$osSkipping"
    } else {
        $vmName = $vm.Name
        $osType = $vm.StorageProfile.OsDisk.OsType
        Write-Output "OS Type:" $osType

        if($osType -eq "Windows"){
            Write-Output "VM Type Detected is Windows"
            $WinVM = remove-azurermvmdiagnosticsextension -ResourceGroupName $vm.ResourceGroupName -VMName $vmName
            $WinVMStatus = $WinVM.Statuses.DisplayStatus
            $WinVM.Statuses.Message | out-file .\Message.txt
            $WinVMMessage = get-content .\Message.txt | select -First 1
            @($WinVMMessage).Replace(",","")
            Add-Content -Path .\RemoveExtLog_$TimeStampLog.csv -Value "$subname,$vmName,$osType,$WinVMStatus,$WinVMMessage"
        } else {
            Write-Output "VM Type Detected is Linux "
            $LinuxVM = remove-azurermvmextension -ResourceGroupName $vm.ResourceGroupName -VMName $vmName -Name LinuxDiagnostic -Force
            $LinuxVMStatus = $LinuxVM.Statuses.DisplayStatus
            $LinuxVM.Statuses.Message | out-file .\Message.txt
            $LinuxVMMessage = get-content .\Message.txt | select -First 1
            @($LinuxVMMessage).Replace(",","")
            Add-Content -Path .\RemoveExtLog_$TimeStampLog.csv -Value "$subname,$vmName,$osType,$LinuxVMStatus,$LinuxVMMessage"
        }
    }
}
