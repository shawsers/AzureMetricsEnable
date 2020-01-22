<#
.VERSION
1.0 - Remove Diagnostic Extension
Updated Date: Jan 22, 2020
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

#This will add the SPNs roles and scope of the subscription and the existing Turbonomic storage account(s)
#You need to specify a correctly formatted CSV file with the "SUBNAME, VMNAME"
#Make sure to update the import-csv file path below with the path to your actual file

#example: .\AzureRemoveExtension.ps1
#>
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
write-host "Starting the script $TimeStamp " -ForegroundColor Green
write-host "Reading input file..." -ForegroundColor Green
$subsandvms = Import-Csv .\subsandvms.csv
login-azurermaccount -ErrorAction Stop
#Add-Content -Path .\AddedAzureRoles.csv -Value "Sub Name,Sub ID,SPN Name,Storage Path Scope,Errors, SPN Role after Chanage, SPN Scope after Change"
foreach ($vm in $subsandvms){
    $vmname = $vm.VMNAME
    $subname = $vm.SUBNAME
    $selectSub = Select-AzureRmSubscription -Subscription $subname
    write-host "starting Sub named ""$subname"" now" -ForegroundColor Green
    write-host "starting VM named ""$vmname"" now" -ForegroundColor Green
    write-host "getting VM power state now" -ForegroundColor Green
    $vmrunning = get-azurermvm -Status | where {$_.Name -eq $vmname} | where {$_.PowerState -eq "VM running"}
    if ($vmrunning -eq $null) {
        write-host "VM named ""$vmname"" is not running.....exiting script...." -ForegroundColor Red -BackgroundColor Black
        Exit
    } else {
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
