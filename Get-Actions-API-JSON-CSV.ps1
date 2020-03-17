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
## Enter the Turbo/CWOM API url here
$url = "https://10.16.172.238/api/v2/markets/_0x3OYUglEd-gHc4L513yOA/"
## Enter the export path for the CSV here
$csvPath = '.\Turbonomic_Actions.csv'
$Credentials = Get-Credential -Credential $null
$RESTAPIUser = $Credentials.UserName
$Credentials.Password | ConvertFrom-SecureString
$RESTAPIPassword = $Credentials.GetNetworkCredential().password
$Header = @{"Authorization" = "Basic "+[System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($RESTAPIUser+":"+$RESTAPIPassword))}
$Type = "application/json"
write-host "gettings actions"
$groups = Invoke-RestMethod -SkipCertificateCheck -Method get -Uri $url'actions' -Headers $Header -ContentType $Type
#$cloudVMGroup = $groups | ?{$_.displayName -eq 'All Cloud VMs'} | select uuid -ExpandProperty uuid
#$entities = Invoke-RestMethod -Method get -Uri $url'groups/'$cloudVMGroup'/entities' -Headers $Header -ContentType $Type
Write-host "output to csv"
#$convert = get-content -Raw $groups | ConvertFrom-Json | Export-CSV $csvPath -NoTypeInformation
Add-Content -Path $csvPath -value "Action Time,Action Type,Entity Name,Entity Type,Resource,From,To,Full Details"
foreach ($group in $groups){
    if ($group.actionType -eq "RIGHT_SIZE"){
        $time = $group.createTime
        $action = $group.actionType
        $target = $group.target.displayName
        $class = $group.target.className
        $comp = $group.currentEntity.className
        $from = $group.currentValue
        $to = $group.resizeToValue
        $details = $group.details
        Add-Content -Path $csvPath -value "$time,$action,$target,$class,$comp,$from,$to,$details"
    }
}
#END OF SCRIPT