<#
.VERSION
1.0 - All Turbonomic SPNs
Updated Date: Oct 25, 2019
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

#This will remove the SPNs roles and scope of the subscription and the existing Turbonomic storage account(s)
#You need to specify a correctly formatted CSV file with the "Sub name, SPN Name, Storage Account name, Storage id/path"
#Make sure to update the import-csv file path below with the path to your actual file

#example: .\AzureRemoveSPNRole.ps1
#>
$spnsubstorage = Import-Csv c:\path\to\file.csv

$error.clear()
$TimeStamp = Get-Date -Format o | foreach {$_ -replace ":", "."}
#Login Azure Account
connect-azurermaccount -ErrorAction Stop
#add logging
foreah ($substorage in $spnsubstorage){
    $sub = $substorage.SUBNAME 
    $spn = $substorage.SPN
    $storage = $substorage.STORAGE 
    $storpath = $substorage.FULLPATH 
    $selectSub = Select-AzureRmSubscription -Subscription $sub
    $turboSPN = get-azurermadserviceprincipal | where-object{$_.DisplayName -eq $spn}
    $spnid = $turboSPN.Id.Guid
    Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName Reader -Scope $storpath
    Remove-AzureRmRoleAssignment -ObjectId $spnid -RoleDefinitionName "Turbonomic Operator ReadOnly" -Scope $storpath
    #add logging
}