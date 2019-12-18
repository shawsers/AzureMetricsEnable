#Created by: Jason.Shaw@turbonomic.com
#Version 1.1 - Dec. 18 at 3PM
#Script to audit Windows and Linux Diagnostic Extensions
#Make sure to create and update the auditsubs.txt file with the names of the subs you want to audit your VM's Diagnostic extensions in
Connect-AzureRmAccount
Add-Content -Path .\VM_Ext_Status.csv -Value "VM Name,OS Name,Sub Name,Resource Group Name,Extension Name,Extension Status,Extension Display Status,Extension Provisioning State,Extension Status Code, Extension Version"
$subs = Get-Content -Path .\auditsubs.txt
foreach($azuresub in $subs){
    $subselect = Select-AzureRmSubscription -SubscriptionName $azuresub
    $subname = $subselect.subscription.name 
    Write-Host "getting list of VM's from $subname"  -ForegroundColor Green
    $vms = get-azurermvm -Status
    Write-Host "getting list of Windows VM's with Diagnostic extension installed"  -ForegroundColor Green
$WinVmsRunning = $vms | where{$_.PowerState -eq 'VM running'} | where{$_.StorageProfile.OsDisk.OsType -eq 'Windows'} | where{$_.Extensions.Id -like '*Microsoft.Insights.VMDiagnosticsSettings*'}
$countwin = ($WinVmsRunning).count
Write-Host "There are $countwin Windows VM's to audit..."  -ForegroundColor Green
foreach ($winvm in $WinVmsRunning) {
    $winvmname = $winvm.name
    $winvmrg = $winvm.resourcegroupname
    $winvmext = Get-AzureRmVMExtension -VMName $winvmname -ResourceGroupName $winvmrg -Name Microsoft.Insights.VMDiagnosticsSettings -Status
    $winvmextstatus = $winvmext.Statuses.level
    $winvmextdisplaystat = $winvmext.Statuses.displaystatus
    $winvmextstatcode = $winvmext.Statuses.code 
    $winvmextprovstat = $winvmext.ProvisioningState
    $winvmextver = $winvmext.TypeHandlerVersion
    $osname = "Windows"
    $extname = "Microsoft.Insights.VMDiagnosticsSettings"
    Add-Content -Path .\VM_Ext_Status.csv -Value "$winvmname,$osname,$subname,$winvmrg,$extname,$winvmextstatus,$winvmextdisplaystat,$winvmextprovstat,$winvmextstatcode,$winvmextver"
}
Write-Host "getting list of Linux VM's with Diagnostic extension installed"  -ForegroundColor Green
$LinVmsRunning = $vms | where{$_.PowerState -eq 'VM running'} | where{$_.StorageProfile.OsDisk.OsType -eq 'Linux'} | where{$_.Extensions.Id -like '*LinuxDiagnostic*'}
$countlin = ($LinVmsRunning).count
Write-Host "There are $countlin Linux VM's to audit..."  -ForegroundColor Green
foreach ($linvm in $LinVmsRunning) {
    $linvmname = $linvm.name
    $linvmrg = $linvm.resourcegroupname
    $linvmext = Get-AzureRmVMExtension -VMName $linvmname -ResourceGroupName $linvmrg -Name LinuxDiagnostic -Status
    $linvmextstatus = $linvmext.Statuses.level
    $linvmextdisplaystat = $linvmext.Statuses.displaystatus
    $linvmextstatcode = $linvmext.Statuses.code 
    $linvmextprovstat = $linvmext.ProvisioningState
    $linvmextver = $linvmext.TypeHandlerVersion
    $losname = "Linux"
    $lextname = "LinuxDiagnostic"
    Add-Content -Path .\VM_Ext_Status.csv -Value "$linvmname,$losname,$subname,$linvmrg,$lextname,$linvmextstatus,$linvmextdisplaystat,$linvmextprovstat,$linvmextstatcode,$linvmextver"
}
}
Write-Host "end of script - please check output file named VM_Ext_Status.csv"  -ForegroundColor Green
#END OF SCRIPT
