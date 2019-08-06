param(

 [Parameter(Mandatory=$True)]
 [string]
 $subscriptionId

)
Login-AzureRmAccount -SubscriptionId $subscriptionId -ErrorAction Stop
$getsub = get-azurermsubscription
$subname = $getsub.Name
$TimeStampLog = Get-Date -Format o | foreach {$_ -replace ":", "."}
$vmList = Get-AzureRmVM
Add-Content -Path .\VerifyLog_$TimeStampLog.csv -Value "Subscription Name,VM Name,OS Type,Extension Status,Extension Message"
if($vmList){
        foreach($vm in $vmList){
            $status=$vm | Get-AzureRmVM -Status $vm.ResourceGroupName
            if ($status.Statuses[1].DisplayStatus -ne "VM running")
            {
                $vmName = $vm.Name
                Write-Output $vmName" is not running. Skipping check"
                $osUnknown = "OS Unknown"
                $osNotRunning = "OS Not Running"
                $osSkipping = "Skipping verification"
                Add-Content -Path .\VerifyLog_$TimeStampLog.csv -Value "$subname,$vmName,$osUnknown,$osNotRunning,$osSkipping"
            } else {
                $vmName = $vm.Name
                $osType = $vm.StorageProfile.OsDisk.OsType
                Write-Output "OS Type:" $osType
        
                if($osType -eq "Windows"){
                    Write-Output "VM Type Detected is Windows"
                    $WinVM = get-azurermvmdiagnosticsextension -ResourceGroupName $vm.ResourceGroupName -VMName $vmName -Name Microsoft.Insights.VMDiagnosticsSettings -Status -Verbose
                    $WinVMStatus = $WinVM.Statuses.DisplayStatus
                    $WinVM.Statuses.Message | out-file .\Message.txt
                    $WinVMMessage = get-content .\Message.txt | select -First 1
                    @($WinVMMessage).Replace(",","")
                    Add-Content -Path .\VerifyLog_$TimeStampLog.csv -Value "$subname,$vmName,$osType,$WinVMStatus,$WinVMMessage"
                } else {
                    Write-Output "VM Type Detected is Linux "
                    $LinuxVM = get-azurermvmextension -ResourceGroupName $vm.ResourceGroupName -VMName $vmName -Name LinuxDiagnostic -Status -Verbose
                    $LinuxVMStatus = $LinuxVM.Statuses.DisplayStatus
                    $LinuxVM.Statuses.Message | out-file .\Message.txt
                    $LinuxVMMessage = get-content .\Message.txt | select -First 1
                    @($LinuxVMMessage).Replace(",","")
                    Add-Content -Path .\VerifyLog_$TimeStampLog.csv -Value "$subname,$vmName,$osType,$LinuxVMStatus,$LinuxVMMessage"
                }

            }
        }
    }