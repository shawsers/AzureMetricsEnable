#START SCRIPT
#Make sure to create a file named subs.txt and add all of the sub names to it you want to run the script on
$login = connect-azurermaccount -ErrorAction Stop
$date = date
Write-Host "Script started at: $date"
Write-Host "Reading input file"
$subs = Get-Content -Path .\subs.txt
Add-Content -Path .\ContributorRole-RGs.csv -Value "Sub Name,RG Name,Role Name,Display Name,Sign In Name,Object Type"
foreach ($sub in $subs){
    Write-host "Starting sub name: $sub"
    $selectsub = Select-AzureRmSubscription -Subscription $sub
    write-host "Getting list of RGs in the sub"
    $allrgs = get-azurermresourcegroup
    foreach ($rg in $allrgs){
        $rgname = $rg.ResourceGroupName
        Write-host "Getting all accounts with Contributor role on the RG named $rgname"
        $contrib = $rg|get-azurermroleassignment|where{$_.RoleDefinitionName -eq "Contributor"}
        foreach ($con in $contrib){
            $displayname = $con.DisplayName
            $signinname = $con.SignInName
            $role = $con.RoleDefinitionName
            $objecttype = $con.ObjectType
            Write-host "Output results to output file"
            Add-Content -Path .\ContributorRole-RGs.csv -Value "$sub,$rgname,$role,$displayname,$signinname,$objecttype"
        }
    }
}
Write-host "Script is complete please review output file ContributorRole-RGs.csv"
#END SCRIPT
