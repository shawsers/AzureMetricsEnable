$Getrg = Get-AzureRmResourceGroup
foreach($rg in $Getrg)
$rgName = $rg.ResourceGroupName
if(($lockedRG = Get-AzureRmResourceLock -ResourceGroupName $rgName | where{$_.Properties.level -eq 'ReadOnly'}) -eq $null){
    Write-Host "No Locks on Resource Group $rgName"
} else {
    Write-Host "ReadOnly Lock found on Resource Group $rgName, Lock needs to be removed before metrics can be enabled"
    Add-Content -Path .\$subname\LockedResourceGroups_$timestamp.csv
}