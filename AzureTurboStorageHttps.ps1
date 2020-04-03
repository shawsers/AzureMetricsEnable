#Read input file named sub-rg-stor.csv that has list of SUBS, RGs and Storage Accounts to have https enabled on
#START SCRIPT
login-azurermaccount -ErrorAction Stop
$list = Import-Csv .\sub-rg-stor.csv -ErrorAction Stop
Add-Content -Path .\TurboStorageHttps.csv -Value "Subscription,Resource Group,Storage Account,EnableHttpsTrafficOnly"
foreach ($item in $list){
    $subname = $item.SUB
    $storrg = $item.RG
    $storacct = $item.STORAGE
    $sub = Select-AzureRmSubscription -Subscription $subname
    Write-host "starting sub: $subname" -ForegroundColor Green
    $setstor = Set-AzureRmStorageAccount -ResourceGroupName $storrg -Name $storacct -EnableHttpsTrafficOnly $true
    Start-Sleep -s 10
    Write-host "Enforcing https traffic only on storage: $storacct" -ForegroundColor Green
    $getstor = Get-AzureRmStorageAccount -ResourceGroupName $storrg -Name $storacct
    $https = $getstor.EnableHttpsTrafficOnly
    Add-Content -Path .\TurboStorageHttps.csv -Value "$subname,$storrg,$storacct,$https"
}
Write-host "Script is complete, check log file TurboStorageHttps.csv for output" -ForegroundColor Green
#END SCRIPT
