## Enter the export path for the CSV here
$csvPath = '.\Turbonomic_Entities.csv'
write-host "gettings actions"
$jsondata = Get-Content -Raw -Path .\Actions.json | ConvertFrom-Json
#$groups = Invoke-RestMethod -Method get -Uri $url'actions' -Headers $Header -ContentType $Type
#$cloudVMGroup = $groups | ?{$_.displayName -eq 'All Cloud VMs'} | select uuid -ExpandProperty uuid
#$entities = Invoke-RestMethod -Method get -Uri $url'groups/'$cloudVMGroup'/entities' -Headers $Header -ContentType $Type
Write-host "output to csv"
#$convert = get-content -Raw $groups | ConvertFrom-Json | Export-CSV $csvPath -NoTypeInformation
Add-Content -Path $csvPath -value "Action Time,Action Type,Entity Name,Entity Type,Resource,From,To,Full Details"
foreach ($group in $jsondata){
    $time = $group.createTime
    $action = $group.actionType
    $target = $group.target.displayName
    $class = $group.target.className
    $comp = $group.currentEntity.className
    $details = $group.details
    $from = $group.currentValue
    $to = $group.resizeToValue
    Add-Content -Path $csvPath -value "$time,$action,$target,$class,$comp,$from,$to,$details"
}