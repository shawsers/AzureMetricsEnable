## Enter the export path for the CSV here
$csvPath = '.\Turbonomic_Groups.csv'
write-host "gettings groups from json file"
$jsondata = Get-Content -Raw -Path .\response_1608044155075.json | ConvertFrom-Json
#$groups = Invoke-RestMethod -Method get -Uri $url'actions' -Headers $Header -ContentType $Type
#$cloudVMGroup = $groups | ?{$_.displayName -eq 'All Cloud VMs'} | select uuid -ExpandProperty uuid
#$entities = Invoke-RestMethod -Method get -Uri $url'groups/'$cloudVMGroup'/entities' -Headers $Header -ContentType $Type
Write-host "output to csv"
#$convert = get-content -Raw $groups | ConvertFrom-Json | Export-CSV $csvPath -NoTypeInformation
Add-Content -Path $csvPath -value "Group UUID,Group Display Name,Group Class,Group Type"
foreach ($group in $jsondata){
    $time = $group.uuid
    $action = $group.displayName
    $target = $group.className
    $class = $group.groupType
    Add-Content -Path $csvPath -value "$time,$action,$target,$class"
}
write-host "script done"