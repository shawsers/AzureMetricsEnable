add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
​
## Enter the Turbo/CWOM API url here
$url = "https://turbonomic2.pwcinternal.com/api/v2/markets/_0x3OYUglEd-gHc4L513yOA/"
​
## Enter the export path for the CSV here
$csvPath = 'C:\Users\jshaw037\Downloads\scripts\output\Turbonomic_Actions.csv'
​
$Credentials = Get-Credential -Credential $null
$RESTAPIUser = $Credentials.UserName
$Credentials.Password | ConvertFrom-SecureString
$RESTAPIPassword = $Credentials.GetNetworkCredential().password
​
$Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($RESTAPIUser+":"+$RESTAPIPassword))}
$Type = "application/json"
write-host "gettings actions"
$groups = Invoke-RestMethod -Method get -Uri $url'actions' -Headers $Header -ContentType $Type
#$cloudVMGroup = $groups | ?{$_.displayName -eq 'All Cloud VMs'} | select uuid -ExpandProperty uuid
#$entities = Invoke-RestMethod -Method get -Uri $url'groups/'$cloudVMGroup'/entities' -Headers $Header -ContentType $Type
Write-host "output to csv"
#$convert = get-content -Raw $groups | ConvertFrom-Json | Export-CSV $csvPath -NoTypeInformation
Add-Content -Path $csvPath -value "Action Time,Action Type,Entity Name,Entity Type,Resource,From,To,Full Details"
foreach ($group in $groups){
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