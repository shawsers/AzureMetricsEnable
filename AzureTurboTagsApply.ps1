#Created by Jason Shaw - jason.shaw@turbonomic.com
#Dated: March 18, 2020
#tags script for Turbo RG's and Storage accounts
login-azurermaccount
$date = date
add-content -Path .\TurboTagsReport.csv -value "Start date and time: $date"
add-content -Path .\TurboTagsReport.csv -value "Resource Type,Name,Sub Name,Resource Group,Current Tags,New Tags"
$azuresub = get-azurermsubscription
foreach ($sub in $azuresub){
    $subname = $sub.Name
    Write-host "Starting sub name: $subname " -ForegroundColor Green
    Select-AzureRmSubscription -SubscriptionObject $sub
    Write-host "getting all RG's with turbo in the name" -ForegroundColor Green
    $turborgs = get-azurermresourcegroup | where{$_.ResourceGroupName -like '*turbo*'}
    foreach($rg in $turborgs) {
        $TagsAsString = $null
        $NewTagsAsString = $null
        $rgname = $rg.ResourceGroupName
        $rgtags = $rg.tags
        $rgtags.GetEnumerator() | % {$TagsAsString += $_.Key + ":" + $_.Value + ";"}
        Write-host "adding tags to RG name: $rgname " -ForegroundColor Green
        Set-AzureRmResourceGroup -name $rgname -tag @{"ghs-solution"="turbonomic_pwcit"; "ghs-environment"="turbonomic_pwcit_prod"; "ghs-los"="ifs"; "ghs-appid"="hycsapp1883"; "ghs-owner"="jerry.trollo@pwc.com"; "ghs-tariff"="zae"; "ghs-apptioid"="globalnis645"}
        $newrgtags = (Get-AzureRmResourceGroup -name $rgname).Tags
        $newrgtags.GetEnumerator() | % {$NewTagsAsString += $_.Key + ":" + $_.Value + ";"}
        add-content -Path .\TurboTagsReport.csv -value "Resource Group,$rgname,$subname,$rgname,$TagsAsString,$NewTagsAsString"
    }
    Write-host "finished adding tags to turbo RG's now" -ForegroundColor Green
    Write-host "getting all storage accounts with turbo in the name" -ForegroundColor Green
    $turbosa = get-azurermstorageaccount | where{$_.StorageAccountName -like '*turbo*'}
    foreach($sa in $turbosa) {
        $TagsAsString = $null
        $NewTagsAsString = $null
        $saname = $sa.StorageAccountName
        $sargname = $sa.ResourceGroupName
        $satags = $sa.tags
        $satags.GetEnumerator() | % {$TagsAsString += $_.Key + ":" + $_.Value + ";"}
        Write-host "adding tags to Storage Account name: $saname " -ForegroundColor Green
        Set-AzureRmStorageAccount -name $saname -ResourceGroupName $sargname -tag @{"ghs-solution"="turbonomic_pwcit"; "ghs-environment"="turbonomic_pwcit_prod"; "ghs-los"="ifs"; "ghs-appid"="hycsapp1883"; "ghs-owner"="jerry.trollo@pwc.com"; "ghs-tariff"="zae"; "ghs-apptioid"="globalnis645"}
        $newsatags = (Get-AzureRmStorageAccount -ResourceGroupName $sargname -name $saname).Tags
        $newsatags.GetEnumerator() | % {$NewTagsAsString += $_.Key + ":" + $_.Value + ";"}
        add-content -Path .\TurboTagsReport.csv -value "Storage Account,$sargname,$subname,$saname,$TagsAsString,$NewTagsAsString"
    }
    Write-host "finished adding tags to turbo Storage Accounts now" -ForegroundColor Green
}
Write-host "finished adding tags to turbo Storage Accounts and RGs now" -ForegroundColor Green
Write-host "please check log output file named: TurboTagsReport.csv " -ForegroundColor Green
$date = date
add-content -Path .\TurboTagsReport.csv -value "Finish date and time: $date"
#END OF SCRIPT
