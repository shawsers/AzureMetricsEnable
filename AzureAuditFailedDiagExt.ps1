#Script to audit Windows and Linux Diagnostic Extensions
Add-Content -Path .\VM_Ext_Status.csv -Value "VM Name,OS Name,Resource Group,Extension Name,Extension Status,Extension Display Status,Extension Provisioning State"
$vms = get-azurermvm -Status
$WinVmsRunning = $vms | where{$_.PowerState -eq ‘VM running’} | where{$_.StorageProfile.OsDisk.OsType -eq ‘Windows’} | where{$_.Extensions.Id -like ‘*Microsoft.Insights.VMDiagnosticsSettings*’}
foreach ($winvm in $WinVmsRunning) {
    $winvmname = $winvm.name
    $winvmrg = $winvm.resourcegroupname
    $winvmext = Get-AzureRmVMExtension -VMName $winvmname -ResourceGroupName $winvmrg -Name Microsoft.Insights.VMDiagnosticsSettings -Status | where {$_.Statuses.level -ne 'Info'}
    $winvmextstatus = $winvmext.Statuses.level
    $winvmextdisplaystat = $winvmext.Statuses.displaystatus
    $winvmextprovstat = $winvmext.ProvisioningState
    $osname = "Windows"
    $extname = "Microsoft.Insights.VMDiagnosticsSettings"
    Add-Content -Path .\VM_Ext_Status.csv -Value "$winvmname,$osname,$winvmrg,$extname,$winvmextstatus,$winvmextdisplaystat,$winvmextprovstat"
}
$LinVmsRunning = $vms | where{$_.PowerState -eq ‘VM running’} | where{$_.StorageProfile.OsDisk.OsType -eq ‘Linux’} | where{$_.Extensions.Id -like ‘*LinuxDiagnostic*’}
foreach ($linvm in $LinVmsRunning) {
    $linvmname = $linvm.name
    $linvmrg = $linvm.resourcegroupname
    $linvmext = Get-AzureRmVMExtension -VMName $linvmname -ResourceGroupName $linvmrg -Name LinuxDiagnostic -Status | where {$_.Statuses.level -ne 'Info'}
    $linvmextstatus = $linvmext.Statuses.level
    $linvmextdisplaystat = $linvmext.Statuses.displaystatus
    $linvmextprovstat = $linvmext.ProvisioningState
    $losname = "Linux"
    $lextname = "LinuxDiagnostic"
    Add-Content -Path .\VM_Ext_Status.csv -Value "$linvmname,$losname,$linvmrg,$lextname,$linvmextstatus,$linvmextdisplaystat,$linvmextprovstat"
}
#END OF SCRIPT
