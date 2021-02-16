#START SCRIPT
#This script will audit your VM's to see what storage account they are writing their diagnostics metrcis to
#If the VM is not running or does not have the diagnostic extension installed it will report that as well in the report
#$subs = get-azsubscription
Add-Content -Path .\Turbo_VM_SA_Info.csv -Value "SUB NAME,VM NAME,VM RG NAME,OS TYPE,STORAGE NAME"
#$login = Login-AzAccount -ErrorAction Stop -InformationAction SilentlyContinue -WarningAction SilentlyContinue
#$subs = get-content -path .\subs.txt
$subs = get-azsubscription
foreach ($sub in $subs){
    $subn = $sub.name
    $selectSub = Get-AzSubscription -SubscriptionName $subn | set-azcontext
    $subname = $selectsub.subscription.name
    write-host "starting sub: $subname" -ForegroundColor Green
    write-host "getting list of all VM's in the sub" -ForegroundColor Green
    $vms = get-azvm
    $winvms = $vms | where {$_.storageprofile.osdisk.ostype -eq 'Windows'}
    $linvms = $vms | where {$_.storageprofile.osdisk.ostype -eq 'Linux'}
    $countwin = ($winvms).count
    Write-host "Starting $countwin Windows VM's" -ForegroundColor Green
    $wincount = 1
    foreach ($winvm in $winvms){
        write-host "starting Windows VM $wincount out of $countwin" -ForegroundColor Green
        $winvmrg = $winvm.resourcegroupname
        $winvmname = $winvm.name
        $winvmrunning = get-azvm -resourcegroup $winvmrg -name $winvmname -status | where {$_.statuses[1].displaystatus -eq 'VM running'} -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
        if ($winvmrunning -eq $null){
            write-host "Windows VM: $winvmname is not running, skipping..." -ForegroundColor Red
            Add-Content -Path .\Turbo_VM_SA_Info.csv -Value "$subname,$winvmname,$winvmrg,Windows,VM IS NOT RUNNING"
        } else { 
            $winextinst = $winvmrunning | where {$_.extensions.name -like 'Microsoft.Insights.VMDiagnosticsSettings'} -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            if ($winextinst -eq $null){
                write-host "Windows VM: $winvmname does not have extension installed, skipping..." -ForegroundColor Red
                Add-Content -Path .\Turbo_VM_SA_Info.csv -Value "$subname,$winvmname,$winvmrg,Windows,NO DIAG EXTENSION INSTALLED"
            } else {
                write-host "Windows VM: $winvmname is running, proceeding..." -ForegroundColor Green
                $winext = get-azvmextension -resourcegroupname $winvmrg -vmname $winvmname -name Microsoft.Insights.VMDiagnosticsSettings -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $getsawin = $winext.publicsettings|convertfrom-json
                $winsa = $getsawin.storageaccount
                Add-Content -Path .\Turbo_VM_SA_Info.csv -Value "$subname,$winvmname,$winvmrg,Windows,$winsa"
            }
        }
        $wincount++
    }
    $countlin = ($linvms).count
    $lincount = 1
    Write-host "Starting $countlin Linux VM's now" -ForegroundColor Green
    foreach ($linvm in $linvms){
        write-host "starting Linux VM $lincount out of $countlin" -ForegroundColor Green
        $linvmrg = $linvm.resourcegroupname
        $linvmname = $linvm.name
        $linvmrunning = get-azvm -resourcegroup $linvmrg -name $linvmname -status | where {$_.statuses[1].displaystatus -eq 'VM running'} -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
        if ($linvmrunning -eq $null){
            write-host "Linux VM: $linvmname is not running, skipping..." -ForegroundColor Red
            Add-Content -Path .\Turbo_VM_SA_Info.csv -Value "$subname,$linvmname,$linvmrg,Linux,VM IS NOT RUNNING"
        } else { 
            $linextinst = $linvmrunning | where {$_.extensions.name -like 'LinuxDiagnostic'} -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
            if ($linextinst -eq $null){
                write-host "Linux VM: $linvmname does not have extension installed, skipping..." -ForegroundColor Red
                Add-Content -Path .\Turbo_VM_SA_Info.csv -Value "$subname,$linvmname,$linvmrg,Linux,NO DIAG EXTENSION INSTALLED"
            } else {
                write-host "Linux VM: $linvmname is running, proceeding..." -ForegroundColor Green
                $linext = get-azvmextension -resourcegroupname $linvmrg -vmname $linvmname -name LinuxDiagnostic -ErrorAction SilentlyContinue -WarningAction SilentlyContinue -InformationAction SilentlyContinue
                $getsalin = $linext.publicsettings|convertfrom-json
                $linsa = $getsalin.storageaccount
                Add-Content -Path .\Turbo_VM_SA_Info.csv -Value "$subname,$linvmname,$linvmrg,Linux,$linsa"
            }
        }
        $lincount++
    }
}
write-host "script is complete, check log file Turbo_VM_SA_Info.csv for details" -ForegroundColor Green
#END OF SCRIPT
