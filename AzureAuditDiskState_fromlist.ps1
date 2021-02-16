#Audit Azure disk state from input file
#Created by: Jason.Shaw@turbonomic.com
#Updated: Oct. 20, 2020

#Input file name needs to be in the same directory you are running the file from
#Input file name needs to be disklist.csv
#Input file contents needs to be in 3 columns with the header names in order: TARGET,RGNAME,DISKNAME
#TARGET is the Azure sub name
#RGNAME is the Azure Resource Group name
#DISKNAME is the Azure Disk Name
#Input example looks like the below (minus the #):
#TARGET,RGNAME,DISKNAME
#My Sub 1,my-rg-one,my-disk-name1
#My Sub 1,my-rg-two,my-disk-name3
#My Other Sub,my-other-rg,my-other-disk

#Check if Azure AZ PowerShell cmdlet is installed
$azurecmdlets = Get-InstalledModule -Name az
if ($azurecmdlets -eq $null){
    Write-Host "Azure AZ module not found, installing.....this can take a few mins to complete...." -ForegroundColor Green
    Install-Module -name az -scope CurrentUser
    Write-Host "Azure AZ module installed, checking..." -ForegroundColor Green
    $azuremodver = get-installedmodule -Name az -MinimumVersion 3.5.0 -ErrorAction SilentlyContinue
    if ($azuremodver -eq $null){
        Write-Host "Azure AZ module not installed, quitting script..." -ForegroundColor Red
        Write-Host "**Please manually install Azure AZ module or try running the script again**" -ForegroundColor Red
        Exit
        #Script exits if the Azure AZ cmdlet not installed as it is required to continue the script
    }
} else {
    $azuremodver = get-installedmodule -Name az -MinimumVersion 3.5.0 -ErrorAction SilentlyContinue
    if ($azuremodver -eq $null){
        Write-Host "Azure AZ module out of date, updating.....this can take a few mins to complete...." -ForegroundColor Green
        #If out of date Azure AZ cmdlet found, it will attempt to update it to the current verison
        Update-Module -Name az -Force
        Write-Host "Azure AZ module updated, continuing..." -ForegroundColor Green
    }
}

#If Azure AZ cmdlet installed then continue
#Login to Aure
login-azaccount -ErrorAction Stop

#verify if the account logged in is correct and ask the user to verify
$con = Get-AzContext
$user = $con.Account.id
write-host "you are currently logged in with userid: $user" -ForegroundColor DarkRed
write-host "you must be logged in with a user that has access to the subs in the input file" -ForegroundColor Green
write-host "if the account above is NOT correct please stop the script by pressing ctrl-C.... and retry with the correct account" -ForegroundColor Green
pause

#START MAIN SCRIPT
$starttime = date
$date = get-date -Format m
$month = $date.replace(" ","_")

#Read Input file
$eudisks = Import-Csv .\disklist.csv

#Create output file
add-content -path .\Disk_State_$month.csv -value "SUB NAME,RG NAME,DISK NAME,DISK SIZE GB,DISK STATE,DISK ID"
foreach ($disk in $eudisks){
    $sub = $disk.TARGET
    $rgname = $disk.RGNAME
    $diskname = $disk.DISKNAME
    $login = Get-AzSubscription -Subscriptionname $sub | set-azcontext
    if ($login -eq $null){
        write-host "No access to sub id: $sub skipping...." -ForegroundColor Red
        add-content -path .\Disk_State_$month.csv -value "$sub,$rgname,$diskname,NO ACCESS TO THE SUB,NO ACCESS TO THE SUB,NO ACCESS TO THE SUB"
    } else {
        $subname = $login.subscription.name
        $getdisk = get-azdisk -resourcegroupname $rgname -diskname $diskname -ErrorAction SilentlyContinue
        if ($getdisk -eq $null){
	    $getdisknorg = get-azdisk | where {$_.Name -eq $diskname}
            if ($getdisknorg -eq $null){
            	write-host "Disk: $diskname in sub: $subname does not exist, skipping..." -ForegroundColor Red
            	add-content -path .\Disk_State_$month.csv -value "$subname,$rgname,$diskname,DISK DOES NOT EXIST,DISK DOES NOT EXIST,DISK DOES NOT EXIST"
	    } else {
		Write-host "Disk: $diskname found in sub: $subname getting disk info..." -ForegroundColor Green
            	$dstate = $getdisknorg.diskstate
            	$dsize = $getdisknorg.disksizegb
            	$did = $getdisknorg.id
		$drg = $getdisknorg.resourcegroupname
            	add-content -path .\Disk_State_$month.csv -value "$subname,$drg,$diskname,$dsize,$dstate,$did"
	    }
        } else {
            Write-host "Disk: $diskname found in sub: $subname getting disk info..." -ForegroundColor Green
            $dstate = $getdisk.diskstate
            $dsize = $getdisk.disksizegb
            $did = $getdisk.id
            add-content -path .\Disk_State_$month.csv -value "$subname,$rgname,$diskname,$dsize,$dstate,$did"
        }
    }
}
$endtime = date
write-host "script started: $starttime" -ForegroundColor Green
write-host "script ended: $endtime" -ForegroundColor Green
write-host "check output file: Disk_State_$month.csv"
#END SCRIPT
#View the output file contents to view the state of each disk
