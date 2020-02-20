## Enter the export path for the CSV here
$csvPath = '.\Turbonomic_Entities.csv'
write-host "gettings actions"
$jsondata = Get-Content -Raw -Path .\Entities.json | ConvertFrom-Json
#$groups = Invoke-RestMethod -Method get -Uri $url'actions' -Headers $Header -ContentType $Type
#$cloudVMGroup = $groups | ?{$_.displayName -eq 'All Cloud VMs'} | select uuid -ExpandProperty uuid
#$entities = Invoke-RestMethod -Method get -Uri $url'groups/'$cloudVMGroup'/entities' -Headers $Header -ContentType $Type
Write-host "output to csv"
#$convert = get-content -Raw $groups | ConvertFrom-Json | Export-CSV $csvPath -NoTypeInformation
Add-Content -Path $csvPath -value "Resource Name,Class,Target,Target Type,Environment,Resource UUID,Resource State"
foreach ($group in $jsondata){
    $name = $group.displayName
    $target = $group.discoveredBy.displayName
    $targettype = $group.discoveredBy.type
    $class = $group.className
    $env = $group.environmentType
    $uuid = $group.uuid
    $state = $group.state
    Add-Content -Path $csvPath -value "$name,$class,$target,$targettype,$env,$uuid,$state"
}