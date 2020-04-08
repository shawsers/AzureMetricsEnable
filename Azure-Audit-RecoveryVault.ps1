#START SCRIPT
#This will list all direct permissions on each Recovery Services Vault in all subs that you have access to
$login = connect-azurermaccount -ErrorAction Stop
$date = date
Write-Host "Script started at: $date" -ForegroundColor Green
$subs = get-azurermsubscription
Add-Content -Path .\AssignedRoles-RecoveryVault.csv -Value "Sub Name,RG Name,Recovery Vault Name,Role Name,Display Name,Sign In Name,Object Type"
foreach ($sub in $subs){
    $selectsub = Select-AzureRmSubscription -SubscriptionObject $sub
    $subname = $selectsub.Subscription.Name
    Write-host "Starting sub name: $subname" -ForegroundColor Green
    write-host "Getting list of Recovery Service Vaults in the sub..." -ForegroundColor Green
    $allrgs = get-azurermrecoveryservicesvault
    foreach ($rg in $allrgs){
        $rgname = $rg.ResourceGroupName
        $vaultname = $rg.Name
        $vaultid = $rg.ID
        Write-host "Getting all accounts with access to the Vault named: $vaultname" -ForegroundColor Green
        $contrib = get-azurermroleassignment -Scope $id | where{$_.Scope -eq $id}
        foreach ($con in $contrib){
            $displayname = $con.DisplayName
            $signinname = $con.SignInName
            $role = $con.RoleDefinitionName
            $objecttype = $con.ObjectType
            Write-host "Output results to output file" -ForegroundColor Green
            Add-Content -Path .\AssignedRoles-RecoveryVault.csv -Value "$subname,$rgname,$vaultname,$role,$displayname,$signinname,$objecttype"
        }
    }
}
Write-host "Script is complete please review output file: AssignedRoles-RecoveryVault.csv" -ForegroundColor Green
#END SCRIPT
