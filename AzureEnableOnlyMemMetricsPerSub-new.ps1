<#
.VERSION
2.5
Updated Date: Nov. 8, 2019 - 5:11PM
Updated By: Jason Shaw 
Email: Jason.Shaw@turbonomic.com

.SYNOPSIS
This script will the enable the defauilt Azure Basic Metrics on all running Windows and Linux VMs in a single subscription that currently don't have metrics enabled.
If the VM already has the metrics enabled it will skip it and output that to the log for tracking.
If the VM is NOT running it will skip it and output that to the log for tracking.

.DESCRIPTION
Use the script to Enable the Default Basic Metrics on all running Windows and Linux VMs in an Azure subscription
The script will configure the VM's to write the metrics to a single pre-existing storage account specified as the storageaccount parameter when running the script
If you run the script and do not specify a pre-existing storage account the script will error out and tell you as such to re-run it.

Create a new folder for the script to run in as it will save logs, xml and json files to the folder the script is run in

To enable for one runnning VM make sure to specify the VM name
 .\AzureEnableMetricsPerSub.ps1 -subscriptionId SUB-ID-HERE -vmname vm_name -resourcegroup resourcegroup_of_vm -storageaccount storageaccount_name

To enable for ALL running VMs in a Subscription just specify your subscription id and storage account where the metrics will be stored in that subscription
 .\AzureEnableMetricsPerSub.ps1 -subscriptionId SUB-ID-HERE -storageaccount storageaccount_name
#>
param(

 [Parameter(Mandatory=$True)]
 [string]
 $subscriptionId,
)

$TimeStampLog = Get-Date -Format o | foreach {$_ -replace ":", "."}
$error.clear()
function Get-TimeStamp {

    return "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)

}

function InstallLinuxExtension($rsgName,$rsgLocation,$vmId,$vmName,$storageName){
    $extensionType="LinuxDiagnostic"
    #$extensionName = "Microsoft.Insights.VMDiagnosticsSettings"
    $extensionName = "LinuxDiagnostic"
    #$vm = Get-AzureRmVM -Name $vmName -ResourceGroupName $rsgName
    #$extension = $vm.Extensions | Where-Object -Property 'VirtualMachineExtensionType' -eq $extensionType
    #if($extension -and $extension.ProvisioningState -eq 'Succeeded'){
    #    $pub = get-azurermvmextension -ResourceGroupName $rsgName -VMName $vmName -Name $extensionType
    #    ($pub.PublicSettings -match '.*StorageAccount.*').matches
    #    $currentsg = $matches[0].split('"')[3]
    #    Write-Output "Diagnostics already installed on the VM : "$vmName " in storage account "$currentsg ".  You need to review or update the extension manually. Skipping Install."
    #    Add-Content -Path .\$subname\InstallLog_$TimeStampLog.csv -Value "'$subname,$vmName,Linux,Skipping Install as diagnostics already installed on the VM: $vmName in Resource Group: $rsgName diagnostics storage currently being used is: $currentsg'"
    #    return
    #}
    Write-Host "Installing VM Extension for your Linux VM" -ForegroundColor Green
    Write-Output "storageName:" $storageName
    ##sastoken moved out of loop

    $jsonfilelinux = '{
  "StorageAccount": "'+$storageName+'",
  "ladCfg": {
    "diagnosticMonitorConfiguration": {
      "eventVolume": "Medium",
      "metrics": {
        "metricAggregation": [
          {
            "scheduledTransferPeriod": "PT1M"
          },
          {
            "scheduledTransferPeriod": "PT1H"
          }
        ],
        "resourceId": "'+$vmId+'"
      },
      "performanceCounters": {
        "performanceCounterConfiguration": [
          {
            "class": "memory",
            "annotation": [
              {
                "displayName": "Memory available",
                "locale": "en-us"
              }
            ],
            "counter": "availablememory",
            "counterSpecifier": "/builtin/memory/availablememory",
            "type": "builtin",
            "unit": "Bytes",
            "sampleRate": "PT15S"
          },
          {
            "class": "memory",
            "annotation": [
              {
                "displayName": "Swap percent used",
                "locale": "en-us"
              }
            ],
            "counter": "percentusedswap",
            "counterSpecifier": "/builtin/memory/percentusedswap",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "class": "memory",
            "annotation": [
              {
                "displayName": "Memory used",
                "locale": "en-us"
              }
            ],
            "counter": "usedmemory",
            "counterSpecifier": "/builtin/memory/usedmemory",
            "type": "builtin",
            "unit": "Bytes",
            "sampleRate": "PT15S"
          },
          {
            "class": "memory",
            "annotation": [
              {
                "displayName": "Page reads",
                "locale": "en-us"
              }
            ],
            "counter": "pagesreadpersec",
            "counterSpecifier": "/builtin/memory/pagesreadpersec",
            "type": "builtin",
            "unit": "CountPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "class": "memory",
            "annotation": [
              {
                "displayName": "Swap available",
                "locale": "en-us"
              }
            ],
            "counter": "availableswap",
            "counterSpecifier": "/builtin/memory/availableswap",
            "type": "builtin",
            "unit": "Bytes",
            "sampleRate": "PT15S"
          },
          {
            "class": "memory",
            "annotation": [
              {
                "displayName": "Swap percent available",
                "locale": "en-us"
              }
            ],
            "counter": "percentavailableswap",
            "counterSpecifier": "/builtin/memory/percentavailableswap",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "class": "memory",
            "annotation": [
              {
                "displayName": "Mem. percent available",
                "locale": "en-us"
              }
            ],
            "counter": "percentavailablememory",
            "counterSpecifier": "/builtin/memory/percentavailablememory",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "class": "memory",
            "annotation": [
              {
                "displayName": "Pages",
                "locale": "en-us"
              }
            ],
            "counter": "pagespersec",
            "counterSpecifier": "/builtin/memory/pagespersec",
            "type": "builtin",
            "unit": "CountPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "class": "memory",
            "annotation": [
              {
                "displayName": "Swap used",
                "locale": "en-us"
              }
            ],
            "counter": "usedswap",
            "counterSpecifier": "/builtin/memory/usedswap",
            "type": "builtin",
            "unit": "Bytes",
            "sampleRate": "PT15S"
          },
          {
            "class": "memory",
            "annotation": [
              {
                "displayName": "Memory percentage",
                "locale": "en-us"
              }
            ],
            "counter": "percentusedmemory",
            "counterSpecifier": "/builtin/memory/percentusedmemory",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "class": "memory",
            "annotation": [
              {
                "displayName": "Page writes",
                "locale": "en-us"
              }
            ],
            "counter": "pageswrittenpersec",
            "counterSpecifier": "/builtin/memory/pageswrittenpersec",
            "type": "builtin",
            "unit": "CountPerSecond",
            "sampleRate": "PT15S"
          }
        ]
      },
      "syslogEvents": {
        "syslogEventConfiguration": {}
      }
    },
    "sampleRateInSeconds": 15
  }
}'
    #$xmlCfgPath =Join-Path $deployExtensionLogDir "linuxxmlcfg.xml";

    #Out-File -FilePath $xmlCfgPath -force -Encoding utf8 -InputObject $xmlCfgContentForLinux

    #$encodingXmlCfg =  [System.Convert]::ToBase64String([system.Text.Encoding]::UTF8.GetBytes($xmlCfgContentForLinux));

    $vmLocation = $rsgLocation
    $settingsString = '{
            "StorageAccount": "'+$storageName+'",
            "xmlCfg": "'+$encodingXmlCfg+'"
    }'
    #$settingsStringPath = Join-Path $deployExtensionLogDir "LinuxSettingsFile.json"

    #Out-File -FilePath $settingsStringPath -Force -Encoding utf8 -InputObject $settingsString

    ##$extensionPublisher = 'Microsoft.OSTCExtensions'
    ##$extensionVersion = "2.3"
    $extensionPublisher = 'Microsoft.Azure.Diagnostics'
    $extensionVersion = "3.0"
    #$storageAll = get-azurermresourcegroup | Get-AzureRmStorageAccount -name $storageName -ErrorAction SilentlyContinue
    $storageAll = get-azurermresourcegroup | where {$_.ResourceGroupName -like '*turbo*'}
    #$storagersgName = $storageAll | where {$_.StorageAccountName -eq $storageName} | Select-Object -ExpandProperty ResourceGroupName
    $storagersgName = $storageAll.ResourceGroupName
    $startdate = [system.datetime]::now.AddDays(-1)
    $enddate = [system.datetime]::Now.AddYears(999)
    $storageKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $StoragersgName -Name $storageName;
    $storageKey = $storageKeys[0].Value;
    $context = new-azurestoragecontext -StorageAccountName $storageName -StorageAccountKey $storageKey
    $storageSas = new-azurestorageaccountsastoken -Service Blob,Table -ResourceType Container,Object -Permission wlacu -Context $context -StartTime $startdate -ExpiryTime $enddate
    $privateCfg = '{
    "storageAccountName": "'+$storageName+'",
    "storageAccountSasToken": "'+$storageSas+'"
    }'

    ##$privateCfg = '{
    ##"storageAccountName": "'+$storageName+'",
    ##"storageAccountSasToken": "'+$storageSas+'"
    #}'
    ##"storageAccountKey": "'+$storageKey+'"
    $extensionType = "LinuxDiagnostic"
    #set this up to run via start-job
    #make sure to remove the -AsJob at the end of the script before adding to start-job
    Set-AzureRmVMExtension -ResourceGroupName $rsgName -VMName $vmName -Name $extensionName -ExtensionType $extensionType -Publisher $extensionPublisher -TypeHandlerVersion $extensionVersion -Settingstring $jsonfilelinux -ProtectedSettingString $privateCfg -Location $vmLocation -AsJob
    ##Set-AzureRmVMExtension -ResourceGroupName $rsgName -VMName $vmName -Name $extensionName -Publisher $extensionPublisher -ExtensionType $extensionType -TypeHandlerVersion $extensionVersion -Settingstring $settingsString -ProtectedSettingString $privateCfg -Location $vmLocation
    ##Set-AzureRmVMDiagnosticsExtension -ResourceGroupName $rsgName -VMName $vmName -StorageAccountName $storagename -StorageAccountKey $storageKey -Name $extensionName -Location $vmLocation -DiagnosticsConfigurationPath $xmlCfgPath -AutoUpgradeMinorVersion $True
}

function InstallWindowsExtension($rsgName,$rsgLocation,$vmId,$vmName,$storageName){
    $extensionName = "Microsoft.Insights.VMDiagnosticsSettings"
    $extensionType = "IaaSDiagnostics"

    #$extension = Get-AzureRmVMDiagnosticsExtension -ResourceGroupName $rsgName -VMName $vmName | Where-Object -Property ExtensionType -eq $extensionType
    #if($extension -and $extension.ProvisioningState -eq 'Succeeded'){
    #    $pub = get-azurermvmextension -ResourceGroupName $rsgName -VMName $vmName -Name $extensionName
    #    ($pub.PublicSettings -match '.*StorageAccount.*').matches
    #    $currentsg = $matches[0].split('"')[3]
    #    Write-Output "Diagnostics already installed on the VM : "$vmName " in storage account "$currentsg ".  You need to review or update the extension manually. Skipping Install."
    #    Add-Content -Path .\$subname\InstallLog_$TimeStampLog.csv -Value "'$subname,$vmName,Windows,Skipping Install as diagnostics already installed on the VM: $vmName in Resource Group: $rsgName diagnostics storage currently being used is: $currentsg'"
    #    return
    #}
    Write-Host "Installing Diagnostic Extension on your Windows VM" -ForegroundColor Green

        Write-Output "storageName:" $storageName
        ##$storageKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $storagersgName -Name $storageName;
        ##$storageKey = $storageKeys[0].Value;

        $vmLocation = $rsgLocation

        $extensionTemplate = '{
  "StorageAccount": "'+$storageName+'",
  "WadCfg": {
    "DiagnosticMonitorConfiguration": {
      "overallQuotaInMB": 5120,
      "Metrics": {
        "resourceId": "'+$vmId+'",
        "MetricAggregation": [
          {
            "scheduledTransferPeriod": "PT1H"
          },
          {
            "scheduledTransferPeriod": "PT1M"
          }
        ]
      },
      "PerformanceCounters": {
        "scheduledTransferPeriod": "PT1M",
        "PerformanceCounterConfiguration": [
          {
            "counterSpecifier": "\\Memory\\% Committed Bytes In Use",
            "unit": "Percent",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Memory\\Available Bytes",
            "unit": "Bytes",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Memory\\Committed Bytes",
            "unit": "Bytes",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Memory\\Cache Bytes",
            "unit": "Bytes",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Memory\\Pool Paged Bytes",
            "unit": "Bytes",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Memory\\Pool Nonpaged Bytes",
            "unit": "Bytes",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Memory\\Pages/sec",
            "unit": "CountPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Memory\\Page Faults/sec",
            "unit": "CountPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Process(_Total)\\Working Set",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Process(_Total)\\Working Set - Private",
            "unit": "Count",
            "sampleRate": "PT60S"
          }
        ]
      },
      "Directories": {
        "scheduledTransferPeriod": "PT1M"
      },
      "WindowsEventLog": {
        "scheduledTransferPeriod": "PT1M",
        "DataSource": []
      }
    }
  }
}'

    #$xmlCfgPath =Join-Path $deployExtensionLogDir "windowsxmlcfg.xml";

    #Out-File -FilePath $xmlCfgPath -force -Encoding utf8 -InputObject $extensiontemplatewin

    #$encodingXmlCfg =  [System.Convert]::ToBase64String([system.Text.Encoding]::UTF8.GetBytes($extensiontemplatewin));

    $extensionTemplatePath = Join-Path $deployExtensionLogDir "extensionTemplateForWindows.json";
    Out-File -FilePath $extensionTemplatePath -Force -Encoding utf8 -InputObject $extensionTemplate
    $storageAll = get-azurermresourcegroup | Get-AzureRmStorageAccount -name $storageName -ErrorAction SilentlyContinue
    $storagersgName = $storageAll | where {$_.StorageAccountName -eq $storageName} | Select-Object -ExpandProperty ResourceGroupName
    $startdate = [system.datetime]::now.AddDays(-1)
    $enddate = [system.datetime]::Now.AddYears(999)
    $storageKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $StoragersgName -Name $storageName;
    $storageKey = $storageKeys[0].Value;
    $context = new-azurestoragecontext -StorageAccountName $storageName -StorageAccountKey $storageKey
    $storageSas = new-azurestorageaccountsastoken -Service Blob,Table -ResourceType Container,Object -Permission wlacu -Context $context -StartTime $startdate -ExpiryTime $enddate
    $privateCfg = '{
    "storageAccountName": "'+$storageName+'",
    "storageAccountSasToken": "'+$storageSas+'"
    }'

    $extensionPublisher = 'Microsoft.Azure.Diagnostics'
    $extensionVersion = "1.5"
    ##"storageAccountKey": "'+$storageKey+'"
    ##Set-AzureRmVMExtension -ResourceGroupName $rsgName -VMName $vmName -Name $extensionName -ExtensionType $extensionType -Publisher $extensionPublisher -TypeHandlerVersion $extensionVersion -Settingstring $extensionTemplate -ProtectedSettingString $privateCfg -Location $vmLocation -AsJob
    ##New-AzureRmResourceGroupDeployment -ResourceGroupName $rsgName -TemplateFile $extensionTemplatePath
    ##Set-AzureRmVMDiagnosticsExtension -ResourceGroupName $rsgName -VMName $vmName -StorageAccountName $storageName -StorageAccountKey $storageKey -Name $extensionName -Location $vmLocation -DiagnosticsConfigurationPath $xmlCfgPath -AutoUpgradeMinorVersion $True
    ####Set-AzureRmVMDiagnosticsExtension -ResourceGroupName $rsgName -VMName $vmName -StorageAccountName $storageName -StorageAccountKey $storageKey -Name $extensionName -Location $vmLocation -DiagnosticsConfigurationPath $extensionTemplatePath -AutoUpgradeMinorVersion $True
    [scriptblock]$sb = { param($rsgName, $vmName, $storageName, $storageKey, $extensionName, $vmLocation, $extensionTemplatePath)
    Set-AzureRmVMDiagnosticsExtension -ResourceGroupName $rsgName -VMName $vmName -StorageAccountName $storageName -StorageAccountKey $storageKey `
    -Name $extensionName -Location $vmLocation -DiagnosticsConfigurationPath $extensionTemplatePath -AutoUpgradeMinorVersion $True
}

Start-Job -Name $vmName -ScriptBlock $sb -ArgumentList $rsgName, $vmName, $storageName, $storageKey, $extensionName, $vmLocation, $extensionTemplatePath

}

$deployExtensionLogDir = split-path -parent $MyInvocation.MyCommand.Definition

if($subscriptionId){
    Login-AzureRmAccount -SubscriptionId $subscriptionId -ErrorAction Stop
    $getsub = get-azurermsubscription -subscriptionId $subscriptionId
    $subname = $getsub.Name
    $selectSub = Select-AzureRmSubscription -Subscription $subscriptionId -InformationAction SilentlyContinue
    if((Test-Path -Path .\$subname) -ne 'True'){
      Write-Host "Creating new sub directory for log files" -ForegroundColor Green
      $path = new-item -Path . -ItemType "directory" -Name $subname -InformationAction SilentlyContinue -ErrorAction Stop
      $fullPath = $path.FullName
    } else {
      Write-Host "Using existing directory for logs" -ForegroundColor Green
      $path = Get-Location
      $fullPath = $path.Path + "\" + $subname 
    }
    #Verify if storage account already exists, if not exit the script
    Write-Host "Verifying if storage account exists..." -ForegroundColor Green
    if(($verifystorage = get-azurermresourcegroup | Get-AzureRmStorageAccount -name $storageaccount -ErrorAction SilentlyContinue) -eq $null){
      write-host "Storage account specified does not exist, please re-run script with a pre-existing storage account" -ForegroundColor Red -BackgroundColor Black
      exit
    } else {
      Write-Host "Storage account found, proceeding..." -ForegroundColor Green 
    }
    $date = date
    Write-Host "**Script started at $date" -ForegroundColor Green
    Write-Host "Getting VM's current status" -ForegroundColor Green
    $vmstat = get-azurermvm -status
    $vmpowerstate = $vmstat | select-object -ExpandProperty "PowerState"

    Write-Host "Saving total VM's and total VM's where power status = running to log file" -ForegroundColor Green
    $date = date
    Add-Content -Path .\$subname\VMsRunningPreChange_$TimeStampLog.csv -Value "Total VM's in Subscription at $date"
    $vmstat.count | out-file .\$subname\VMsRunningPreChange_$TimeStampLog.csv -Append ascii
    Add-Content -Path .\$subname\VMsRunningPreChange_$TimeStampLog.csv -Value " "
    Add-Content -Path .\$subname\VMsRunningPreChange_$TimeStampLog.csv -Value "VM's Running Before Change at $date"
    @($vmpowerstate | ? {$_ -eq "VM running"}).count | out-file .\$subname\VMsRunningPreChange_$TimeStampLog.csv -Append ascii
    Add-Content -Path .\$subname\VMsRunningPreChange_$TimeStampLog.csv -Value " "
    $vmstat | out-file .\$subname\VMsRunningPreChange_$TimeStampLog.csv -Append ascii
    Write-host "Finished saving VM's running to log file" -ForegroundColor Green

} else {
    Login-AzureRmAccount -ErrorAction Stop
}

$vmList = $null
if($vmname -and $storageaccount){
    Write-Output "Selected Resource Group: " $resourcegroup " VM Name:" $vmname
    $vmStatus = Get-AzureRmVM -Name $vmname -ResourceGroupName $resourcegroup -Status | Where-Object{$_.Statuses[1].DisplayStatus -eq 'VM running'}
    if($vmStatus -eq $null){
      Write-Host "VM must be running to enable metrics, skipping VM" -ForegroundColor Red -BackgroundColor Black
    } else {
      $vmList = Get-AzureRmVM -Name $vmname -ResourceGroupName $resourcegroup
      Write-Host "Checking if VM is running, if it is Windows or Linux and if metrics enabled yet or not..." -ForegroundColor Green
      $LinuxVmsRunning = $vmList | where{$_.PowerState -eq 'VM running'} | where{$_.StorageProfile.OsDisk.OsType -eq 'Linux'} | where{$_.Extensions.Id -notlike '*LinuxDiagnostic*'}
      $WinVmsRunning = $vmList | where{$_.PowerState -eq 'VM running'} | where{$_.StorageProfile.OsDisk.OsType -eq 'Windows'} | where{$_.Extensions.Id -notlike '*Microsoft.Insights.VMDiagnosticsSettings*'}  
    }
    Add-Content -Path .\$subname\InstallLog_$TimeStampLog.csv -Value 'Date and Time,Subscription Name,VM Name,OS Type,Errors'
}
elseif($storageaccount) {
    Write-Host "Getting all VM's in the subscription" -ForegroundColor Green
    $vmList = Get-AzureRmVM -Status
    Write-Host "Getting list of running Linux VMs that do not have metrics enabled yet..." -ForegroundColor Green
    $LinuxVmsRunning = $vmList | where{$_.PowerState -eq 'VM running'} | where{$_.StorageProfile.OsDisk.OsType -eq 'Linux'} | where{$_.Extensions.Id -notlike '*LinuxDiagnostic*'}
    Write-Host "Getting list of running Windows VMs that do not have metrics enabled yet..." -ForegroundColor Green
    $WinVmsRunning = $vmList | where{$_.PowerState -eq 'VM running'} | where{$_.StorageProfile.OsDisk.OsType -eq 'Windows'} | where{$_.Extensions.Id -notlike '*Microsoft.Insights.VMDiagnosticsSettings*'}
    Write-Host "Getting list of VMs that are NOT running and logging that for later..." -ForegroundColor Green
    $vmsNotRunning = $vmList | where{$_.PowerState -ne 'VM running'}
    if($vmsNotRunning -eq $null){
      Write-Host "All VMs in the subscription are running" -ForegroundColor Green
    } else {
      Add-Content -Path .\$subname\VMsNotRunning_$TimeStampLog.csv -Value "Total NOT Running VMs in Subscription at $date"
      Add-Content -Path .\$subname\VMsNotRunning_$TimeStampLog.csv -Value "These VMs have to be powered on before metrics can be enabled"
      ($vmsNotRunning).count | out-file .\$subname\VMsNotRunning_$TimeStampLog.csv -Append ascii
      Add-Content -Path .\$subname\VMsNotRunning_$TimeStampLog.csv -Value " "
      $vmsNotRunning | out-file .\$subname\VMsNotRunning_$TimeStampLog.csv -Append ascii
    }
    Add-Content -Path .\$subname\InstallLog_$TimeStampLog.csv -Value 'Date and Time,Subscription Name,VM Name,OS Type,Errors'
    Write-Host "Getting list of Rersource Groups..." -ForegroundColor Green
    $Getrg = Get-AzureRmResourceGroup -ErrorAction SilentlyContinue
    Write-Host "Checking for any ReadOnly locks on the Resource Groups..." -ForegroundColor Green
    foreach($rgr in $Getrg){
      $rgrName = $rgr.ResourceGroupName
      if(($lockedRG = Get-AzureRmResourceLock -ResourceGroupName $rgrName | where{$_.Properties.level -eq 'ReadOnly'}) -eq $null){
        Write-Host "No ReadOnly lock found on Resource Group $rgrName" -ForegroundColor Green
      } else {
        Write-Host "ReadOnly lock found on Resource Group $rgrName, Lock needs to be removed before metrics can be enabled on the VMs" -ForegroundColor Red -BackgroundColor Black
        Add-Content -Path .\$subname\LockedResourceGroups_$TimeStampLog.csv -Value 'Subscription Name, Resource Group, Comment'
        $comment = "ReadOnly lock needs to be removed before metrics can be enabled on the VMs in the Resource Group"
        Add-Content -Path .\$subname\LockedResourceGroups_$TimeStampLog.csv -Value "$subname, $rgrName, $comment"
      }
    }
}

if($vmList){
    $vmsCompleted = 0
    Write-Host "Starting Windows VMs" -ForegroundColor Green
    foreach($vm in $WinVmsRunning){
        #$status=$vm | Get-AzureRmVM -Status $vm.ResourceGroupName
        #if ($status.Statuses[1].DisplayStatus -ne "VM running")
        #{
        #    Write-Output $vm.Name" is not running. Skipping install."
        #    $vmName = $vm.Name
        #    Add-Content -Path .\$subname\InstallLog_$TimeStampLog.csv -Value "'$subname,$vmname,Not Running,Error VM Not Running power on VM and run again'"
        #    continue
        #}
        $countjobs = (get-job -state Running).count
        Write-Host "Number of running jobs is ""$countjobs""" -ForegroundColor Green
        Write-Host "Number of VMs completed is ""$vmsCompleted""" -ForegroundColor Green
        
        while((get-job -State Running).count -ge 50){start-sleep 1}

        $rsgName = $vm.ResourceGroupName;
        $rsg = Get-AzureRmResourceGroup -Name $rsgName
        $rsgLocation = $vm.Location;

        $storageName = $storageaccount

        $vmId = $vm.Id
        $vmName = $vm.Name
        Write-Output "VM ID:" $vmId
        Write-Output "VM Name:" $vmName
        Write-Host "VM Type Detected is Windows" -ForegroundColor Green
        $error.clear()
        InstallWindowsExtension -rsgName $rsgName -rsgLocation $rsgLocation -vmId $vmId -vmName $vmName -storageName $storageName
        $WinOS = "Windows"
        $date = date
        Add-Content -Path .\$subname\InstallLog_$TimeStampLog.csv -Value "$date,$subname,$vmName,$WinOS,$error"

        $failedJobs = get-job -State Failed | Receive-Job
        $failedJobs | export-csv -Path .\$subname\Failed_$TimeStampLog.csv -Append -Force
        $completedJobs = get-job -State Completed | Receive-Job
        $completedJobs | export-csv -Path .\$subname\Completed_$TimeStampLog.csv -Append -Force
        get-job -State Completed | remove-job -confirm:$false -force
        get-job -State Failed | remove-job -confirm:$false -force
        $vmsCompleted++
    }
  Write-Host "Starting Linux VMs" -ForegroundColor Green
    foreach($vm in $LinuxVmsRunning){
      $countjobs = (get-job -state Running).count
      Write-Host "Number of running jobs is ""$countjobs""" -ForegroundColor Green
      Write-Host "Number of VMs completed is ""$vmsCompleted""" -ForegroundColor Green

      while((get-job -State Running).count -ge 50){start-sleep 1}

      $rsgName = $vm.ResourceGroupName;
      $rsg = Get-AzureRmResourceGroup -Name $rsgName
      $rsgLocation = $vm.Location;

      $storageName = $storageaccount

      $vmId = $vm.Id
      $vmName = $vm.Name
      Write-Output "VM ID:" $vmId
      Write-Output "VM Name:" $vmName

      Write-Host "VM Type Detected is Linux" -ForegroundColor Green
      $error.clear()
      InstallLinuxExtension -rsgName $rsgName -rsgLocation $rsgLocation -vmId $vmId -vmName $vmName -storageName $storageName
      $LinOS = "Linux"
      $date = date
      Add-Content -Path .\$subname\InstallLog_$TimeStampLog.csv -Value "$date,$subname,$vmName,$LinOS,$error"

      $failedJobs = get-job -State Failed | Receive-Job
      $failedJobs | export-csv -Path .\$subname\Failed_$TimeStampLog.csv -Append -Force
      $completedJobs = get-job -State Completed | Receive-Job
      $completedJobs | export-csv -Path .\$subname\Completed_$TimeStampLog.csv -Append -Force
      get-job -State Completed | remove-job -confirm:$false -force
      get-job -State Failed | remove-job -confirm:$false -force
      $vmsCompleted++
    }
} else {
    Write-Host "Couldn't find any powered on VMs in your subscription" -ForegroundColor Red -BackgroundColor Black
    Write-Output "Couldn't find any powered on VMs in your subscription" | Out-File -FilePath .\$subname\NoVMs_$TimeStampLog.csv
    $date = date
    Write-Host "**Script finished at $date " -ForegroundColor Green
    Write-Host "**Check path: ""$fullPath"" for the logs" -ForegroundColor Green
    Exit
}
Write-Host "Waiting for all background jobs to complete now...this can take some time" -ForegroundColor Green
Write-Host "Waiting for up to 25 mins for all background jobs to complete..." -ForegroundColor Green
#New logic to check for long running job and finish the job after so many mins and save job info
if((get-job -state Running).count -gt 0) {
  $runningJobs = get-job -state Running
  $runJobsCount = $runningJobs.count
  Write-Host "There are still ""$runJobsCount"" job(s) running, waiting for 5 mins..." -ForegroundColor Red -BackgroundColor Black
  start-sleep 300
}
if((get-job -state Running).count -gt 0) {
  $runningJobs = get-job -state Running
  $runJobsCount = $runningJobs.count
  Write-Host "There are still ""$runJobsCount"" job(s) running, waiting another 5 mins..." -ForegroundColor Red -BackgroundColor Black
  start-sleep 300
}
if((get-job -state Running).count -gt 0) {
  $runningJobs = get-job -state Running
  $runJobsCount = $runningJobs.count
  Write-Host "There are still ""$runJobsCount"" job(s) running, waiting yet another 5 mins..." -ForegroundColor Red -BackgroundColor Black
  start-sleep 300
}
if((get-job -state Running).count -gt 0) {
  $runningJobs = get-job -state Running
  $runJobsCount = $runningJobs.count
  Write-Host "There are still ""$runJobsCount"" job(s) running, waiting yet another 5 mins...yes this does take time..." -ForegroundColor Red -BackgroundColor Black
  start-sleep 300
}
if((get-job -state Running).count -gt 0) {
  $runningJobs = get-job -state Running
  $runJobsCount = $runningJobs.count
  Write-Host "There are still ""$runJobsCount"" job(s) running, waiting final 5 mins..." -ForegroundColor Red -BackgroundColor Black
  start-sleep 300
}
$runningJobs = get-job -state Running
$runJobsCount = $runningJobs.count
if (($runningJobs.count) -gt 0){
  Write-Host "There are still ""$runJobsCount"" job(s) running in the background listed below that need to be looked into further" -ForegroundColor Red -BackgroundColor Black
  $runningJobs
  $count = 0
  foreach($runningJob in $runningJobs){
    $count++
    $jobId = $runningJob.Id
    Receive-Job -Id $jobId | Out-File .\$subname\LongRunningJob_$count.txt
  }
} else {
  Write-Host "All background jobs have finished running now, saving job log files" -ForegroundColor Green
}
#while((get-job -State Running).count -gt 0){start-sleep 5}
$failedJobs = get-job -State Failed | Receive-Job
$failedJobs | export-csv -Path .\$subname\Failed_$TimeStampLog.csv -Append -Force
$completedJobs = get-job -State Completed | Receive-Job
$completedJobs | export-csv -Path .\$subname\Completed_$TimeStampLog.csv -Append -Force
get-job -State Completed | remove-job -confirm:$false -force
get-job -State Failed | remove-job -confirm:$false -force
Write-Host "Getting status of VM's post change" -ForegroundColor Green
$vmstat = get-azurermvm -status
$vmpowerstate = $vmstat | select-object -ExpandProperty "PowerState"
$date = date
Add-Content -Path .\$subname\VMsRunningPostChange_$TimeStampLog.csv -Value "VM's Running After Change at $date"
Write-Host "Saving VM's running to log file" -ForegroundColor Green
@($vmpowerstate | ? {$_ -eq "VM running"}).count | out-file .\$subname\VMsRunningPostChange_$TimeStampLog.csv -Append ascii
Add-Content -Path .\$subname\VMsRunningPostChange_$TimeStampLog.csv -Value " "
$vmstat | out-file .\$subname\VMsRunningPostChange_$TimeStampLog.csv -Append ascii
$date = date
Write-Host "**Script finished at $date " -ForegroundColor Green
Write-Host "**Check path: ""$fullPath"" for the logs" -ForegroundColor Green