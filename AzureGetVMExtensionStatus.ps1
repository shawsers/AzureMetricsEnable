param(

 [Parameter(Mandatory=$True)]
 [string]
 $subscriptionId

)
Login-AzureRmAccount -SubscriptionId $subscriptionId -ErrorAction Stop
$selectSub = Select-AzureRmSubscription -Subscription $subscriptionId
$getsub = get-azurermsubscription -SubscriptionId $subscriptionId
$subname = $getsub.Name
$date = date
Write-Host "**Script started at $date" -ForegroundColor Green
if((Test-Path -Path .\$subname) -ne 'True'){
    Write-Host "Creating new sub directory for log files" -ForegroundColor Green
    $path = new-item -Path . -ItemType "directory" -Name $subname -InformationAction SilentlyContinue -ErrorAction Stop
    $fullPath = $path.FullName
  } else {
    Write-Host "Using existing directory for logs" -ForegroundColor Green
    $path = Get-Location
    $fullPath = $path.Path + "\" + $subname 
  }
$TimeStampLog = Get-Date -Format o | foreach {$_ -replace ":", "."}
Write-Host "Getting VM list" -ForegroundColor Green
$vmList = Get-AzureRmVM
Add-Content -Path .\$subname\VerifyLog_$TimeStampLog.csv -Value "Subscription Name,VM Name,OS Type,Extension Status,Extension Message"
if($vmList){
    #add get-job logic to check for running jobs
    Write-Host "Getting status of each VM..." -ForegroundColor Green
        foreach($vm in $vmList){
            $status=$vm | Get-AzureRmVM -Status $vm.ResourceGroupName
            if ($status.Statuses[1].DisplayStatus -ne "VM running")
            {
                $vmName = $vm.Name
                Write-Output $vmName" is not running. Skipping check"
                $osUnknown = "OS Unknown"
                $osNotRunning = "OS Not Running"
                $osSkipping = "Skipping verification"
                Add-Content -Path .\$subname\VerifyLog_$TimeStampLog.csv -Value "$subname,$vmName,$osUnknown,$osNotRunning,$osSkipping"
            } else {
                $vmName = $vm.Name
                $osType = $vm.StorageProfile.OsDisk.OsType
                if($osType -eq "Windows"){
                    Write-Host "VM: ""$vmName"" Type Detected is Windows" -ForegroundColor Green
                    #add start-job to run as background job
                    if(($WinVM = get-azurermvmdiagnosticsextension -ResourceGroupName $vm.ResourceGroupName -VMName $vmName -Name Microsoft.Insights.VMDiagnosticsSettings -Status -Verbose -ErrorAction SilentlyContinue) -eq $null){
                        Write-Host "Extension NOT found on VM: ""$vmName"" " -ForegroundColor Red -BackgroundColor Black
                        $WinVMStatus = "Extension NOT found"
                        $WinVMMessage = "Extension NOT installed"
                        Add-Content -Path .\$subname\VerifyLog_$TimeStampLog.csv -Value "$subname,$vmName,$osType,$WinVMStatus,$WinVMMessage"  
                    } else {
                        Write-Host "Extension found on VM: ""$vmName"" " -ForegroundColor Green
                        $WinVMStatus = $WinVM.Statuses.DisplayStatus
                        $WinVM.Statuses.Message | out-file .\$subname\Message.txt
                        $WinVMMessage = get-content .\$subname\Message.txt | select -First 1
                        @($WinVMMessage).Replace(",","")
                        Add-Content -Path .\$subname\VerifyLog_$TimeStampLog.csv -Value "$subname,$vmName,$osType,$WinVMStatus,$WinVMMessage"
                    }
                } else {
                    Write-Host "VM: ""$vmName"" Type Detected is Linux" -ForegroundColor Green
                    #add start-job to run as background job
                    if(($LinuxVM = get-azurermvmextension -ResourceGroupName $vm.ResourceGroupName -VMName $vmName -Name LinuxDiagnostic -Status -Verbose -ErrorAction SilentlyContinue) -eq $null){
                        Write-Host "Extension NOT found on VM: ""$vmName"" " -ForegroundColor Red -BackgroundColor Black
                        $LinuxVMStatus = "Extension NOT found"
                        $LinuxVMMessage = "Extension NOT installed"
                        Add-Content -Path .\$subname\VerifyLog_$TimeStampLog.csv -Value "$subname,$vmName,$osType,$LinuxVMStatus,$LinuxVMMessage"
                    } else {
                        Write-Host "Extension found on VM: ""$vmName"" " -ForegroundColor Green
                        $LinuxVMStatus = $LinuxVM.Statuses.DisplayStatus
                        $LinuxVM.Statuses.Message | out-file .\$subname\Message.txt
                        $LinuxVMMessage = get-content .\$subname\Message.txt | select -First 1
                        @($LinuxVMMessage).Replace(",","")
                        Add-Content -Path .\$subname\VerifyLog_$TimeStampLog.csv -Value "$subname,$vmName,$osType,$LinuxVMStatus,$LinuxVMMessage"
                    }
                }
            }
        }
    }
    #add logic to check for long running jobs
    #remember to add logic for jobs running for over 5 mins to cancel them and capture job detail
    $date = date
    Write-Host "**Script finished at $date " -ForegroundColor Green
    Write-Host "**Check path: ""$fullPath"" for the logs" -ForegroundColor Green