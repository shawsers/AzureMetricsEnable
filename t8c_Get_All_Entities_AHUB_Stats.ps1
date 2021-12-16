#This PowerShell script will query the Turbonomic/CWOM API for Cloud VM's and list their AHUB status
#It will prompt for the URL of the Turbo/CWOM Server to query and for the username and password

$turboInstance = read-host -prompt 'input Turbo/CWOM servername like: https://servername.com'
$loginURI = "$turboInstance/vmturbo/rest/login"
$apiBaseUri = "$turboInstance/vmturbo/rest"
$date = get-date -format MMddyyyyHHmm
if(!($securePassword)){$SecurePassword = read-host -AsSecureString -Prompt "Enter your password"}
Add-Content -Path .\AHUB_$date.csv -Value "VM Name,Operating System,State,Target Name,Target Type,AHUB Enabled"
$username = read-host -prompt 'input username'
$creds = New-Object PSCredential $username, $SecurePassword

$contentType = "application/json"

$credsBody = @{
    username = $creds.UserName
    password = $creds.GetNetworkCredential().Password
}
$count = 0
$cou = 500
$cursor = 500
$statsJson = $null
$entites = $null
while($cursor){
    $login = Invoke-WebRequest $loginURI -SessionVariable Sess -Body $credsBody -Method 'POST' -SkipCertificateCheck
    write-host "starting"
    $enturi = "$apiBaseUri/markets/Market/entities?cursor=" + "$cou"
    $statsResponse = Invoke-WebRequest -WebSession $Sess -uri $enturi -SkipCertificateCheck
    $statsJson = ConvertFrom-Json $($statsResponse.Content) -AsHashtable
    $cursor = $statsResponse.Headers["X-Next-Cursor"]
    $total = $statsResponse.Headers['X-Total-Record-Count']
    $count += $statsJson.Count
    #$entites += $statsJson
    write-host "$cou of $total"
    $cou = $cou + 500
$entcount = ($statsJson).count
$entnum = 1
foreach($ent in $statsJson){
    write-host "parsing stat $entnum out of $entcount"
    $uuid = ($ent.uuid).tostring()
    if($ent.className -eq "VirtualMachine"){
        if($ent.discoveredBy.category -eq "Public Cloud"){
        $displayname = $ent.displayName
        write-host "found VM $displayname"
        $state = $ent.state
        $discname = $ent.discoveredBy.displayName
        $disctype = $ent.discoveredBy.type
        $statsuri = "$apiBaseUri/entities/" + $($ent.uuid).ToString() + "/aspects"
        $response = Invoke-RestMethod -WebSession $Sess -uri $statsuri -ContentType $contentType -SkipCertificateCheck
        $os = $response.virtualMachineAspect.os
        $heap = ($response.virtualMachineAspect | Where-Object {$_.ahublicense -eq "true"})
        $entnum = $entnum + 1
        if($heap -eq $null){
            write-host "no found AHUB on VM $displayname"
            Add-Content -Path .\AHUB_$date.csv -Value "$displayname,$os,$state,$discname,$disctype,False"
        } else {
            write-host "AHUB found on VM $displayname"
            Add-Content -Path .\AHUB_$date.csv -Value "$displayname,$os,$state,$discname,$disctype,True"
            }
        }
    }
    }
}
write-host "script finished check file - AHUB_$date.csv"
#END SCRIPT
