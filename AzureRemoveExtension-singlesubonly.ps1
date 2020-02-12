<#
.VERSION
1.0 - Remove Diagnostic Extension - single sub only
Updated Date: Feb, 12 2020
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

#This will add the SPNs roles and scope of the subscription and the existing Turbonomic storage account(s)
#You need to specify a correctly formatted CSV file with the column headers "SUBNAME and VMNAME and the list of each under that heading"
#Make sure to store the input file named "subsandvms.csv" in the same directory as the script is being run

#example: .\AzureRemoveExtension.ps1 -subname AZURE-SUB-NAME
#>
param(

 [Parameter(Mandatory=$True)]
 [string]
 $subname
)
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
write-host "Starting the script $TimeStamp " -ForegroundColor Green
write-host "Reading input file..." -ForegroundColor Green
$subsandvms = Import-Csv .\subsandvms.csv
$countvms = ($subsandvms).count
Write-Host "there is a total of $countvms to be processed....." -ForegroundColor Green
login-azurermaccount -ErrorAction Stop
#Add-Content -Path .\AddedAzureRoles.csv -Value "Sub Name,Sub ID,SPN Name,Storage Path Scope,Errors, SPN Role after Chanage, SPN Scope after Change"
Add-Content -Path .\PoweredOffVMs.csv -Value "Powered Off VMs"
Add-Content -Path .\CompletedVMs.csv -Value "Completed VMs"
Add-Content -Path .\CompletedVMs-verifiedremoved.csv -Value "VM's Ext Removed"
Add-Content -Path .\CompletedVMs-verifiedNOTremoved.csv -Value "VM's Ext NOT Removed"
$vmscompleted = 0
Write-Host "Clearing all completed background jobs..." -ForegroundColor Green
$removejobs = get-job -State Completed | Remove-Job -Force -Confirm:$false
$selectSub = Select-AzureRmSubscription -Subscription $subname
$getvms = get-azurermvm -Status
foreach ($vm in $subsandvms){
    $vmname = $vm.VMNAME
    write-host "starting VM named ""$vmname"" now" -ForegroundColor Green
    write-host "getting VM power state now" -ForegroundColor Green
    $vmrunning = $getvms | where {$_.Name -eq $vmname} | where {$_.PowerState -eq "VM running"}
    if ($vmrunning -eq $null) {
        write-host "VM named ""$vmname"" is not running.....skipping VM...." -ForegroundColor Red -BackgroundColor Black
        Add-Content -Path .\PoweredOffVMs.csv -Value "$vmname"
    } else {
        Write-Host "There have been $vmscompleted VMs completed so far..."
        $numjobs = (get-job -State Running).count
        write-host "There are currently $numjobs background jobs running...." -ForegroundColor Green
        $osType = $vmrunning.StorageProfile.OsDisk.OsType
        Write-Output "OS Type:" $osType
        if($osType -eq "Windows"){
            Write-Output "VM Type Detected is Windows"
            $vmrg = $vmrunning.ResourceGroupName
            #$windiag = "Microsoft.Insights.VMDiagnosticsSettings"
            [scriptblock]$winsb = { param($vmrg, $vmname) remove-azurermvmextension -ResourceGroupName $vmrg -VMName $vmname -Name Microsoft.Insights.VMDiagnosticsSettings -Force }
            while((get-job -State Running).count -ge 25){start-sleep 1}
            Start-Job -Name $vmname -ScriptBlock $winsb -ArgumentList $vmrg, $vmname
            $vmscompleted++
            foreach ($job in (get-job -state Completed)){
                $jobname = $job.Name
                Add-Content -Path .\CompletedVMs.csv -Value "$jobname"
                get-job -Name $jobname | Remove-Job -Force -Confirm:$false
            }
            #$WinVM = remove-azurermvmdiagnosticsextension -ResourceGroupName $vmrg -VMName $vmname
            #$WinVMStatus = $WinVM.Statuses.DisplayStatus
            #$WinVM.Statuses.Message | out-file .\Message.txt
            #$WinVMMessage = get-content .\Message.txt | select -First 1
            #@($WinVMMessage).Replace(",","")
            #Add-Content -Path .\RemoveExtLog_$TimeStampLog.csv -Value "$subname,$vmname,$osType,$WinVMStatus,$WinVMMessage"
        } else {
            Write-Output "VM Type Detected is Linux "
            $linrg = $vmrunning.ResourceGroupName
            #$lindiag = "LinuxDiagnostic"
            [scriptblock]$linsb = { param($linrg, $vmname) remove-azurermvmextension -ResourceGroupName $linrg -VMName $vmname -Name LinuxDiagnostic -Force }
            while((get-job -State Running).count -ge 25){start-sleep 1}
            Start-Job -Name $vmname -ScriptBlock $linsb -ArgumentList $linrg, $vmname
            $vmscompleted++
            foreach ($job in (get-job -state Completed)){
                $jobname = $job.Name
                Add-Content -Path .\CompletedVMs.csv -Value "$jobname"
                get-job -Name $jobname | Remove-Job -Force -Confirm:$false
            }
            #$LinuxVM = remove-azurermvmextension -ResourceGroupName $linrg -VMName $vmname -Name LinuxDiagnostic -Force
            #$LinuxVMStatus = $LinuxVM.Statuses.DisplayStatus
            #$LinuxVM.Statuses.Message | out-file .\Message.txt
            #$LinuxVMMessage = get-content .\Message.txt | select -First 1
            #@($LinuxVMMessage).Replace(",","")
            #Add-Content -Path .\RemoveExtLog_$TimeStampLog.csv -Value "$subname,$vmname,$osType,$LinuxVMStatus,$LinuxVMMessage"
        }
    }
}
if((get-job -state Running).count -gt 0) {
    $runningJobs = get-job -state Running
    $runJobsCount = $runningJobs.count
    Write-Host "There are still ""$runJobsCount"" job(s) running, waiting for 5 mins..." -ForegroundColor Red -BackgroundColor Black
    start-sleep 300
  }
  if((get-job -state Running).count -gt 0) {
    $runningJobs = get-job -state Running
    $runJobsCount = $runningJobs.count
    Write-Host "There are still ""$runJobsCount"" job(s) running, waiting another 5 mins..." -ForegroundColor Red -BackgroundColor Black
    start-sleep 300
  }
  if((get-job -state Running).count -gt 0) {
    $runningJobs = get-job -state Running
    $runJobsCount = $runningJobs.count
    Write-Host "There are still ""$runJobsCount"" job(s) running, waiting yet another 5 mins..." -ForegroundColor Red -BackgroundColor Black
    start-sleep 300
  }
  if((get-job -state Running).count -gt 0) {
    $runningJobs = get-job -state Running
    $runJobsCount = $runningJobs.count
    Write-Host "There are still ""$runJobsCount"" job(s) running, waiting yet another 5 mins...yes this does take time..." -ForegroundColor Red -BackgroundColor Black
    start-sleep 300
  }
  if((get-job -state Running).count -gt 0) {
    $runningJobs = get-job -state Running
    $runJobsCount = $runningJobs.count
    Write-Host "There are still ""$runJobsCount"" job(s) running, waiting final 5 mins..." -ForegroundColor Red -BackgroundColor Black
    start-sleep 300
  }
foreach ($job in (get-job -state Completed)){
    $jobname = $job.Name
    Add-Content -Path .\CompletedVMs.csv -Value "$jobname"
    get-job -Name $jobname | Remove-Job -Force -Confirm:$false
}
foreach ($vm in $subsandvms){
    $vmname = $vm.VMNAME
    $subname = $vm.SUBNAME
    $selectSub = Select-AzureRmSubscription -Subscription $subname
    write-host "starting post validation of all VM's in the input file now, this will take some time....." -ForegroundColor Green
    $vmcheck = get-azurermvm -Status | where {$_.Name -eq $vmname} | where {$_.PowerState -eq "VM running"}
    if ($vmcheck -ne $null){
        $ext = $vmcheck.Extensions.Id 
    }
    if ($vmcheck -eq $null){
        Write-Host "VM $vmname is powered off, skipping..." -ForegroundColor Red -BackgroundColor Black
    } elseif ($vmcheck.StorageProfile.OsDisk.OsType -eq "Windows") {
        if ((select-string -Pattern "Microsoft.Insights.VMDiagnosticsSettings" -InputObject $ext) -eq $null) {
            Write-Host "Windows VM diagnostics extension removed from VM $vmname" -ForegroundColor Green
            Add-Content -Path .\CompletedVMs-verifiedremoved.csv -Value "$vmname"
        } else {
            Write-Host "Windows VM diagnostic extension was NOT removed from VM $vmname" -ForegroundColor Red -BackgroundColor Black
            Add-Content -Path .\CompletedVMs-verifiedNOTremoved.csv -Value "$vmname"
        }
    } elseif ($vmcheck.StorageProfile.OsDisk.OsType -eq "Linux") {
        if ((select-string -Pattern "LinuxDiagnostic" -InputObject $ext) -eq $null) {
            Write-Host "Linux VM diagnostics extension removed from VM $vmname" -ForegroundColor Green
            Add-Content -Path .\CompletedVMs-verifiedremoved.csv -Value "$vmname"
        } else {
            Write-Host "Linux VM diagnostic extension was NOT removed from VM $vmname" -ForegroundColor Red -BackgroundColor Black
            Add-Content -Path .\CompletedVMs-verifiedNOTremoved.csv -Value "$vmname"
        }
    }   
}
Write-Host "script has completed, please make sure to review the output files PoweredOffVMs.csv, CompletedVMs.csv, CompletedVMs-verifiedremoved.csv, CompletedVMs-verifiedNOTremoved.csv" -ForegroundColor Green
#END OF SCRIPT