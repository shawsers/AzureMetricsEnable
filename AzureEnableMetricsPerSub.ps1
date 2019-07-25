<#
.VERSION
1.0

.SYNOPSIS
This script will the enable the defauilt Azure Basic Metrics on all running Windows and Linux VMs in a single subscription that currently don't have metrics enabled.
If the VM already has the metrics enabled it will skip it and output that to the log for tracking.
If the VM is NOT running it will skip it and output that to the log for tracking.

.DESCRIPTION
Use the script to Enable the Default Basic Metrics on all running Windows and Linux VMs in an Azure subscription
The script will configure the VM's to write the metris to a single storage account specified as the storageaccount parameter when running the script
 
Create a new folder for the script to run in as it will save logs, xml and json files to the folder the script is run in

To enable for one runnning VM make sure to specify the VM name
 .\AzureMetrics.ps1' -subscriptionId SUB-ID-HERE -vmname “vmname" -storageaccount "storageaccount"

To enable for ALL running VMs in a Subscription just specify your subscription id and storage account where the metrics will be stored in that subscription
 .\AzureMetrics.ps1' -subscriptionId SUB-ID-HERE -storageaccount "storageaccount"
#>
param(

 [Parameter(Mandatory=$True)]
 [string]
 $subscriptionId,

 [Parameter(Mandatory=$False)]
 [string]
 $resourcegroup,

 [Parameter(Mandatory=$False)]
 [string]
 $vmname,

 [Parameter(Mandatory=$True)]
 [string]
 $storageaccount
)

$TimeStampLog = Get-Date -Format o | foreach {$_ -replace ":", "."}
$error.clear()
function Get-TimeStamp {
    
    return "[{0:dd/MM/yy} {0:HH:mm:ss}]" -f (Get-Date)
    
}

function InstallLinuxExtension($rsgName,$rsgLocation,$vmId,$vmName, $storageaccount){
    $extensionType="LinuxDiagnostic"
    #$extensionName = "Microsoft.Insights.VMDiagnosticsSettings"
    $extensionName = "LinuxDiagnostic"
    $vm = Get-AzureRmVM -Name $vmName -ResourceGroupName $rsgName
    $extension = $vm.Extensions | Where-Object -Property 'VirtualMachineExtensionType' -eq $extensionType
    if($extension -and $extension.ProvisioningState -eq 'Succeeded'){
        $pub = get-azurermvmextension -ResourceGroupName $rsgName -VMName $vmName -Name $extensionType
        ($pub.PublicSettings -match '.*StorageAccount.*').matches
        $currentsg = $matches[0].split('"')[3]
        Write-Host "Diagnostics already installed on the VM : "$vmName " in storage account "$currentsg ".  You need to review or update the extension manually. Skipping Install."
        Add-Content -Path .\InstallLog_$TimeStampLog.csv -Value "'$subname,$vmName,Linux,Skipping Install as diagnostics already installed on the VM: $vmName in Resource Group: $rsgName diagnostics storage currently being used is: $currentsg'"
        return
    }
    Write-Host "Installing VM Extension for your Linux VM"
    Write-Host "storageName:" $storageName
    ##sastoken moved out of loop

    $xmlCfgContentForLinux ='<WadCfg><DiagnosticMonitorConfiguration overallQuotaInMB="4096"><DiagnosticInfrastructureLogs scheduledTransferPeriod="PT1M" scheduledTransferLogLevelFilter="Warning"/><PerformanceCounters scheduledTransferPeriod="PT1M"><PerformanceCounterConfiguration counterSpecifier="\Memory\AvailableMemory" sampleRate="PT15S" unit="Bytes"><annotation displayName="Memory available" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Memory\PercentAvailableMemory" sampleRate="PT15S" unit="Percent"><annotation displayName="Mem. percent available" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Memory\UsedMemory" sampleRate="PT15S" unit="Bytes"><annotation displayName="Memory used" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Memory\PercentUsedMemory" sampleRate="PT15S" unit="Percent"><annotation displayName="Memory percentage" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Memory\PercentUsedByCache" sampleRate="PT15S" unit="Percent"><annotation displayName="Mem. used by cache" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Memory\PagesPerSec" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Pages" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Memory\PagesReadPerSec" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Page reads" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Memory\PagesWrittenPerSec" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Page writes" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Memory\AvailableSwap" sampleRate="PT15S" unit="Bytes"><annotation displayName="Swap available" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Memory\PercentAvailableSwap" sampleRate="PT15S" unit="Percent"><annotation displayName="Swap percent available" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Memory\UsedSwap" sampleRate="PT15S" unit="Bytes"><annotation displayName="Swap used" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Memory\PercentUsedSwap" sampleRate="PT15S" unit="Percent"><annotation displayName="Swap percent used" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Processor\PercentIdleTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU idle time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Processor\PercentUserTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU user time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Processor\PercentNiceTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU nice time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Processor\PercentPrivilegedTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU privileged time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Processor\PercentInterruptTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU interrupt time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Processor\PercentDPCTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU DPC time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Processor\PercentProcessorTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU percentage guest OS" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\Processor\PercentIOWaitTime" sampleRate="PT15S" unit="Percent"><annotation displayName="CPU IO wait time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\PhysicalDisk\BytesPerSecond" sampleRate="PT15S" unit="BytesPerSecond"><annotation displayName="Disk total bytes" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\PhysicalDisk\ReadBytesPerSecond" sampleRate="PT15S" unit="BytesPerSecond"><annotation displayName="Disk read guest OS" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\PhysicalDisk\WriteBytesPerSecond" sampleRate="PT15S" unit="BytesPerSecond"><annotation displayName="Disk write guest OS" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\PhysicalDisk\TransfersPerSecond" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Disk transfers" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\PhysicalDisk\ReadsPerSecond" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Disk reads" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\PhysicalDisk\WritesPerSecond" sampleRate="PT15S" unit="CountPerSecond"><annotation displayName="Disk writes" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\PhysicalDisk\AverageReadTime" sampleRate="PT15S" unit="Seconds"><annotation displayName="Disk read time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\PhysicalDisk\AverageWriteTime" sampleRate="PT15S" unit="Seconds"><annotation displayName="Disk write time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\PhysicalDisk\AverageTransferTime" sampleRate="PT15S" unit="Seconds"><annotation displayName="Disk transfer time" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\PhysicalDisk\AverageDiskQueueLength" sampleRate="PT15S" unit="Count"><annotation displayName="Disk queue length" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\NetworkInterface\BytesTransmitted" sampleRate="PT15S" unit="Bytes"><annotation displayName="Network out guest OS" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\NetworkInterface\BytesReceived" sampleRate="PT15S" unit="Bytes"><annotation displayName="Network in guest OS" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\NetworkInterface\PacketsTransmitted" sampleRate="PT15S" unit="Count"><annotation displayName="Packets sent" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\NetworkInterface\PacketsReceived" sampleRate="PT15S" unit="Count"><annotation displayName="Packets received" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\NetworkInterface\BytesTotal" sampleRate="PT15S" unit="Bytes"><annotation displayName="Network total bytes" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\NetworkInterface\TotalRxErrors" sampleRate="PT15S" unit="Count"><annotation displayName="Packets received errors" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\NetworkInterface\TotalTxErrors" sampleRate="PT15S" unit="Count"><annotation displayName="Packets sent errors" locale="en-us"/></PerformanceCounterConfiguration><PerformanceCounterConfiguration counterSpecifier="\NetworkInterface\TotalCollisions" sampleRate="PT15S" unit="Count"><annotation displayName="Network collisions" locale="en-us"/></PerformanceCounterConfiguration></PerformanceCounters><Metrics resourceId="'+$vmId+'"><MetricAggregation scheduledTransferPeriod="PT1H"/><MetricAggregation scheduledTransferPeriod="PT1M"/></Metrics></DiagnosticMonitorConfiguration></WadCfg>'
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
      "syslogEvents": {
        "syslogEventConfiguration": {
        }
      },
      "performanceCounters": {
        "performanceCounterConfiguration": [
          {
            "annotation": [
              {
                "displayName": "CPU IO wait time",
                "locale": "en-us"
              }
            ],
            "class": "processor",
            "condition": "IsAggregate=TRUE",
            "counter": "percentiowaittime",
            "counterSpecifier": "/builtin/processor/percentiowaittime",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "CPU user time",
                "locale": "en-us"
              }
            ],
            "class": "processor",
            "condition": "IsAggregate=TRUE",
            "counter": "percentusertime",
            "counterSpecifier": "/builtin/processor/percentusertime",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "CPU nice time",
                "locale": "en-us"
              }
            ],
            "class": "processor",
            "condition": "IsAggregate=TRUE",
            "counter": "percentnicetime",
            "counterSpecifier": "/builtin/processor/percentnicetime",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "CPU percentage guest OS",
                "locale": "en-us"
              }
            ],
            "class": "processor",
            "condition": "IsAggregate=TRUE",
            "counter": "percentprocessortime",
            "counterSpecifier": "/builtin/processor/percentprocessortime",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "CPU interrupt time",
                "locale": "en-us"
              }
            ],
            "class": "processor",
            "condition": "IsAggregate=TRUE",
            "counter": "percentinterrupttime",
            "counterSpecifier": "/builtin/processor/percentinterrupttime",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "CPU idle time",
                "locale": "en-us"
              }
            ],
            "class": "processor",
            "condition": "IsAggregate=TRUE",
            "counter": "percentidletime",
            "counterSpecifier": "/builtin/processor/percentidletime",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "CPU privileged time",
                "locale": "en-us"
              }
            ],
            "class": "processor",
            "condition": "IsAggregate=TRUE",
            "counter": "percentprivilegedtime",
            "counterSpecifier": "/builtin/processor/percentprivilegedtime",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Memory available",
                "locale": "en-us"
              }
            ],
            "class": "memory",
            "counter": "availablememory",
            "counterSpecifier": "/builtin/memory/availablememory",
            "type": "builtin",
            "unit": "Bytes",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Swap percent used",
                "locale": "en-us"
              }
            ],
            "class": "memory",
            "counter": "percentusedswap",
            "counterSpecifier": "/builtin/memory/percentusedswap",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Memory used",
                "locale": "en-us"
              }
            ],
            "class": "memory",
            "counter": "usedmemory",
            "counterSpecifier": "/builtin/memory/usedmemory",
            "type": "builtin",
            "unit": "Bytes",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Page reads",
                "locale": "en-us"
              }
            ],
            "class": "memory",
            "counter": "pagesreadpersec",
            "counterSpecifier": "/builtin/memory/pagesreadpersec",
            "type": "builtin",
            "unit": "CountPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Swap available",
                "locale": "en-us"
              }
            ],
            "class": "memory",
            "counter": "availableswap",
            "counterSpecifier": "/builtin/memory/availableswap",
            "type": "builtin",
            "unit": "Bytes",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Swap percent available",
                "locale": "en-us"
              }
            ],
            "class": "memory",
            "counter": "percentavailableswap",
            "counterSpecifier": "/builtin/memory/percentavailableswap",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Mem. percent available",
                "locale": "en-us"
              }
            ],
            "class": "memory",
            "counter": "percentavailablememory",
            "counterSpecifier": "/builtin/memory/percentavailablememory",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Pages",
                "locale": "en-us"
              }
            ],
            "class": "memory",
            "counter": "pagespersec",
            "counterSpecifier": "/builtin/memory/pagespersec",
            "type": "builtin",
            "unit": "CountPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Swap used",
                "locale": "en-us"
              }
            ],
            "class": "memory",
            "counter": "usedswap",
            "counterSpecifier": "/builtin/memory/usedswap",
            "type": "builtin",
            "unit": "Bytes",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Memory percentage",
                "locale": "en-us"
              }
            ],
            "class": "memory",
            "counter": "percentusedmemory",
            "counterSpecifier": "/builtin/memory/percentusedmemory",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Page writes",
                "locale": "en-us"
              }
            ],
            "class": "memory",
            "counter": "pageswrittenpersec",
            "counterSpecifier": "/builtin/memory/pageswrittenpersec",
            "type": "builtin",
            "unit": "CountPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Network in guest OS",
                "locale": "en-us"
              }
            ],
            "class": "network",
            "counter": "bytesreceived",
            "counterSpecifier": "/builtin/network/bytesreceived",
            "type": "builtin",
            "unit": "Bytes",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Network total bytes",
                "locale": "en-us"
              }
            ],
            "class": "network",
            "counter": "bytestotal",
            "counterSpecifier": "/builtin/network/bytestotal",
            "type": "builtin",
            "unit": "Bytes",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Network out guest OS",
                "locale": "en-us"
              }
            ],
            "class": "network",
            "counter": "bytestransmitted",
            "counterSpecifier": "/builtin/network/bytestransmitted",
            "type": "builtin",
            "unit": "Bytes",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Network collisions",
                "locale": "en-us"
              }
            ],
            "class": "network",
            "counter": "totalcollisions",
            "counterSpecifier": "/builtin/network/totalcollisions",
            "type": "builtin",
            "unit": "Count",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Packets received errors",
                "locale": "en-us"
              }
            ],
            "class": "network",
            "counter": "totalrxerrors",
            "counterSpecifier": "/builtin/network/totalrxerrors",
            "type": "builtin",
            "unit": "Count",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Packets sent",
                "locale": "en-us"
              }
            ],
            "class": "network",
            "counter": "packetstransmitted",
            "counterSpecifier": "/builtin/network/packetstransmitted",
            "type": "builtin",
            "unit": "Count",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Packets received",
                "locale": "en-us"
              }
            ],
            "class": "network",
            "counter": "packetsreceived",
            "counterSpecifier": "/builtin/network/packetsreceived",
            "type": "builtin",
            "unit": "Count",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Packets sent errors",
                "locale": "en-us"
              }
            ],
            "class": "network",
            "counter": "totaltxerrors",
            "counterSpecifier": "/builtin/network/totaltxerrors",
            "type": "builtin",
            "unit": "Count",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Filesystem transfers/sec",
                "locale": "en-us"
              }
            ],
            "class": "filesystem",
            "condition": "IsAggregate=TRUE",
            "counter": "transferspersecond",
            "counterSpecifier": "/builtin/filesystem/transferspersecond",
            "type": "builtin",
            "unit": "CountPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Filesystem % free space",
                "locale": "en-us"
              }
            ],
            "class": "filesystem",
            "condition": "IsAggregate=TRUE",
            "counter": "percentfreespace",
            "counterSpecifier": "/builtin/filesystem/percentfreespace",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Filesystem % used space",
                "locale": "en-us"
              }
            ],
            "class": "filesystem",
            "condition": "IsAggregate=TRUE",
            "counter": "percentusedspace",
            "counterSpecifier": "/builtin/filesystem/percentusedspace",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Filesystem used space",
                "locale": "en-us"
              }
            ],
            "class": "filesystem",
            "condition": "IsAggregate=TRUE",
            "counter": "usedspace",
            "counterSpecifier": "/builtin/filesystem/usedspace",
            "type": "builtin",
            "unit": "Bytes",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Filesystem read bytes/sec",
                "locale": "en-us"
              }
            ],
            "class": "filesystem",
            "condition": "IsAggregate=TRUE",
            "counter": "bytesreadpersecond",
            "counterSpecifier": "/builtin/filesystem/bytesreadpersecond",
            "type": "builtin",
            "unit": "CountPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Filesystem free space",
                "locale": "en-us"
              }
            ],
            "class": "filesystem",
            "condition": "IsAggregate=TRUE",
            "counter": "freespace",
            "counterSpecifier": "/builtin/filesystem/freespace",
            "type": "builtin",
            "unit": "Bytes",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Filesystem % free inodes",
                "locale": "en-us"
              }
            ],
            "class": "filesystem",
            "condition": "IsAggregate=TRUE",
            "counter": "percentfreeinodes",
            "counterSpecifier": "/builtin/filesystem/percentfreeinodes",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Filesystem bytes/sec",
                "locale": "en-us"
              }
            ],
            "class": "filesystem",
            "condition": "IsAggregate=TRUE",
            "counter": "bytespersecond",
            "counterSpecifier": "/builtin/filesystem/bytespersecond",
            "type": "builtin",
            "unit": "BytesPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Filesystem reads/sec",
                "locale": "en-us"
              }
            ],
            "class": "filesystem",
            "condition": "IsAggregate=TRUE",
            "counter": "readspersecond",
            "counterSpecifier": "/builtin/filesystem/readspersecond",
            "type": "builtin",
            "unit": "CountPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Filesystem write bytes/sec",
                "locale": "en-us"
              }
            ],
            "class": "filesystem",
            "condition": "IsAggregate=TRUE",
            "counter": "byteswrittenpersecond",
            "counterSpecifier": "/builtin/filesystem/byteswrittenpersecond",
            "type": "builtin",
            "unit": "CountPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Filesystem writes/sec",
                "locale": "en-us"
              }
            ],
            "class": "filesystem",
            "condition": "IsAggregate=TRUE",
            "counter": "writespersecond",
            "counterSpecifier": "/builtin/filesystem/writespersecond",
            "type": "builtin",
            "unit": "CountPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Filesystem % used inodes",
                "locale": "en-us"
              }
            ],
            "class": "filesystem",
            "condition": "IsAggregate=TRUE",
            "counter": "percentusedinodes",
            "counterSpecifier": "/builtin/filesystem/percentusedinodes",
            "type": "builtin",
            "unit": "Percent",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Disk read guest OS",
                "locale": "en-us"
              }
            ],
            "class": "disk",
            "condition": "IsAggregate=TRUE",
            "counter": "readbytespersecond",
            "counterSpecifier": "/builtin/disk/readbytespersecond",
            "type": "builtin",
            "unit": "BytesPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Disk writes",
                "locale": "en-us"
              }
            ],
            "class": "disk",
            "condition": "IsAggregate=TRUE",
            "counter": "writespersecond",
            "counterSpecifier": "/builtin/disk/writespersecond",
            "type": "builtin",
            "unit": "CountPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Disk transfer time",
                "locale": "en-us"
              }
            ],
            "class": "disk",
            "condition": "IsAggregate=TRUE",
            "counter": "averagetransfertime",
            "counterSpecifier": "/builtin/disk/averagetransfertime",
            "type": "builtin",
            "unit": "Seconds",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Disk transfers",
                "locale": "en-us"
              }
            ],
            "class": "disk",
            "condition": "IsAggregate=TRUE",
            "counter": "transferspersecond",
            "counterSpecifier": "/builtin/disk/transferspersecond",
            "type": "builtin",
            "unit": "CountPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Disk write guest OS",
                "locale": "en-us"
              }
            ],
            "class": "disk",
            "condition": "IsAggregate=TRUE",
            "counter": "writebytespersecond",
            "counterSpecifier": "/builtin/disk/writebytespersecond",
            "type": "builtin",
            "unit": "BytesPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Disk read time",
                "locale": "en-us"
              }
            ],
            "class": "disk",
            "condition": "IsAggregate=TRUE",
            "counter": "averagereadtime",
            "counterSpecifier": "/builtin/disk/averagereadtime",
            "type": "builtin",
            "unit": "Seconds",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Disk write time",
                "locale": "en-us"
              }
            ],
            "class": "disk",
            "condition": "IsAggregate=TRUE",
            "counter": "averagewritetime",
            "counterSpecifier": "/builtin/disk/averagewritetime",
            "type": "builtin",
            "unit": "Seconds",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Disk total bytes",
                "locale": "en-us"
              }
            ],
            "class": "disk",
            "condition": "IsAggregate=TRUE",
            "counter": "bytespersecond",
            "counterSpecifier": "/builtin/disk/bytespersecond",
            "type": "builtin",
            "unit": "BytesPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Disk reads",
                "locale": "en-us"
              }
            ],
            "class": "disk",
            "condition": "IsAggregate=TRUE",
            "counter": "readspersecond",
            "counterSpecifier": "/builtin/disk/readspersecond",
            "type": "builtin",
            "unit": "CountPerSecond",
            "sampleRate": "PT15S"
          },
          {
            "annotation": [
              {
                "displayName": "Disk queue length",
                "locale": "en-us"
              }
            ],
            "class": "disk",
            "condition": "IsAggregate=TRUE",
            "counter": "averagediskqueuelength",
            "counterSpecifier": "/builtin/disk/averagediskqueuelength",
            "type": "builtin",
            "unit": "Count",
            "sampleRate": "PT15S"
          }
        ]
      }
    },
    "sampleRateInSeconds": 15
  }
}'
    $xmlCfgPath =Join-Path $deployExtensionLogDir "linuxxmlcfg.xml";

    Out-File -FilePath $xmlCfgPath -force -Encoding utf8 -InputObject $xmlCfgContentForLinux

    $encodingXmlCfg =  [System.Convert]::ToBase64String([system.Text.Encoding]::UTF8.GetBytes($xmlCfgContentForLinux));

    $vmLocation = $rsgLocation
    $settingsString = '{
            "StorageAccount": "'+$storageName+'",
            "xmlCfg": "'+$encodingXmlCfg+'"
    }'
    $settingsStringPath = Join-Path $deployExtensionLogDir "LinuxSettingsFile.json"

    Out-File -FilePath $settingsStringPath -Force -Encoding utf8 -InputObject $settingsString

    ##$extensionPublisher = 'Microsoft.OSTCExtensions'
    ##$extensionVersion = "2.3"
    $extensionPublisher = 'Microsoft.Azure.Diagnostics'
    $extensionVersion = "3.0"
    ##$privateCfg = '{
    ##"storageAccountName": "'+$storageName+'",
    ##"storageAccountSasToken": "'+$storageSas+'"
    #}'
    ##"storageAccountKey": "'+$storageKey+'"
    $extensionType = "LinuxDiagnostic"
    Set-AzureRmVMExtension -ResourceGroupName $rsgName -VMName $vmName -Name $extensionName -ExtensionType $extensionType -Publisher $extensionPublisher -TypeHandlerVersion $extensionVersion -Settingstring $jsonfilelinux -ProtectedSettingString $privateCfg -Location $vmLocation -AsJob
    ##Set-AzureRmVMExtension -ResourceGroupName $rsgName -VMName $vmName -Name $extensionName -Publisher $extensionPublisher -ExtensionType $extensionType -TypeHandlerVersion $extensionVersion -Settingstring $settingsString -ProtectedSettingString $privateCfg -Location $vmLocation
    ##Set-AzureRmVMDiagnosticsExtension -ResourceGroupName $rsgName -VMName $vmName -StorageAccountName $storagename -StorageAccountKey $storageKey -Name $extensionName -Location $vmLocation -DiagnosticsConfigurationPath $xmlCfgPath -AutoUpgradeMinorVersion $True
}

function InstallWindowsExtension($rsgName,$rsgLocation,$vmId,$vmName, $storageaccount){
    $extensionName = "Microsoft.Insights.VMDiagnosticsSettings"
    $extensionType = "IaaSDiagnostics"
   
    $extension = Get-AzureRmVMDiagnosticsExtension -ResourceGroupName $rsgName -VMName $vmName | Where-Object -Property ExtensionType -eq $extensionType
    if($extension -and $extension.ProvisioningState -eq 'Succeeded'){
        $pub = get-azurermvmextension -ResourceGroupName $rsgName -VMName $vmName -Name $extensionName
        ($pub.PublicSettings -match '.*StorageAccount.*').matches
        $currentsg = $matches[0].split('"')[3]
        Write-Host "Diagnostics already installed on the VM : "$vmName " in storage account "$currentsg ".  You need to review or update the extension manually. Skipping Install."
        Add-Content -Path .\InstallLog_$TimeStampLog.csv -Value "'$subname,$vmName,Windows,Skipping Install as diagnostics already installed on the VM: $vmName in Resource Group: $rsgName diagnostics storage currently being used is: $currentsg'"

        return
    }
    Write-Host "Installing Diagnostic Extension on your Windows VM"

        Write-Host "storageName:" $storageName
        $storageKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $storagersgName -Name $storageName;
        $storageKey = $storageKeys[0].Value;

        $vmLocation = $rsgLocation

        $extensionTemplateWin = '<WadCfg xmlns="http://schemas.microsoft.com/ServiceHosting/2010/10/DiagnosticsConfiguration">  <DiagnosticMonitorConfiguration overallQuotaInMB="5120">    <DiagnosticInfrastructureLogs scheduledTransferLogLevelFilter="Error" scheduledTransferPeriod="PT1M"/>    <PerformanceCounters scheduledTransferPeriod="PT1M"><PerformanceCounterConfiguration counterSpecifier="\Processor Information(_Total)\% Processor Time" sampleRate="PT60S" unit="Percent"/><PerformanceCounterConfiguration counterSpecifier="\Processor Information(_Total)\% Privileged Time" sampleRate="PT60S" unit="Percent"/><PerformanceCounterConfiguration counterSpecifier="\Processor Information(_Total)\% User Time" sampleRate="PT60S" unit="Percent"/><PerformanceCounterConfiguration counterSpecifier="\Processor Information(_Total)\Processor Frequency" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\System\Processes" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Process(_Total)\Thread Count" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Process(_Total)\Handle Count" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\System\System Up Time" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\System\Context Switches/sec" sampleRate="PT60S" unit="CountPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\System\Processor Queue Length" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Memory\% Committed Bytes In Use" sampleRate="PT60S" unit="Percent"/><PerformanceCounterConfiguration counterSpecifier="\Memory\Available Bytes" sampleRate="PT60S" unit="Bytes"/><PerformanceCounterConfiguration counterSpecifier="\Memory\Committed Bytes" sampleRate="PT60S" unit="Bytes"/><PerformanceCounterConfiguration counterSpecifier="\Memory\Cache Bytes" sampleRate="PT60S" unit="Bytes"/><PerformanceCounterConfiguration counterSpecifier="\Memory\Pool Paged Bytes" sampleRate="PT60S" unit="Bytes"/><PerformanceCounterConfiguration counterSpecifier="\Memory\Pool Nonpaged Bytes" sampleRate="PT60S" unit="Bytes"/><PerformanceCounterConfiguration counterSpecifier="\Memory\Pages/sec" sampleRate="PT60S" unit="CountPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\Memory\Page Faults/sec" sampleRate="PT60S" unit="CountPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\Process(_Total)\Working Set" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Process(_Total)\Working Set - Private" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\% Disk Time" sampleRate="PT60S" unit="Percent"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\% Disk Read Time" sampleRate="PT60S" unit="Percent"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\% Disk Write Time" sampleRate="PT60S" unit="Percent"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\% Idle Time" sampleRate="PT60S" unit="Percent"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\Disk Bytes/sec" sampleRate="PT60S" unit="BytesPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\Disk Read Bytes/sec" sampleRate="PT60S" unit="BytesPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\Disk Write Bytes/sec" sampleRate="PT60S" unit="BytesPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\Disk Transfers/sec" sampleRate="PT60S" unit="BytesPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\Disk Reads/sec" sampleRate="PT60S" unit="BytesPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\Disk Writes/sec" sampleRate="PT60S" unit="BytesPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\Avg. Disk sec/Transfer" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\Avg. Disk sec/Read" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\Avg. Disk sec/Write" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\Avg. Disk Queue Length" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\Avg. Disk Read Queue Length" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\Avg. Disk Write Queue Length" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\% Free Space" sampleRate="PT60S" unit="Percent"/><PerformanceCounterConfiguration counterSpecifier="\LogicalDisk(_Total)\Free Megabytes" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Network Interface(*)\Bytes Total/sec" sampleRate="PT60S" unit="BytesPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\Network Interface(*)\Bytes Sent/sec" sampleRate="PT60S" unit="BytesPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\Network Interface(*)\Bytes Received/sec" sampleRate="PT60S" unit="BytesPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\Network Interface(*)\Packets/sec" sampleRate="PT60S" unit="BytesPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\Network Interface(*)\Packets Sent/sec" sampleRate="PT60S" unit="BytesPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\Network Interface(*)\Packets Received/sec" sampleRate="PT60S" unit="BytesPerSecond"/><PerformanceCounterConfiguration counterSpecifier="\Network Interface(*)\Packets Outbound Errors" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Network Interface(*)\Packets Received Errors" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Exceptions(w3wp)\# of Exceps Thrown / sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Interop(w3wp)\# of marshalling" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Jit(w3wp)\% Time in Jit" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Loading(w3wp)\Current appdomains" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Loading(w3wp)\Current Assemblies" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Loading(w3wp)\% Time Loading" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Loading(w3wp)\Bytes in Loader Heap" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR LocksAndThreads(w3wp)\Contention Rate / sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR LocksAndThreads(w3wp)\Current Queue Length" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Memory(w3wp)\# Gen 0 Collections" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Memory(w3wp)\# Gen 1 Collections" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Memory(w3wp)\# Gen 2 Collections" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Memory(w3wp)\% Time in GC" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Memory(w3wp)\# Bytes in all Heaps" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Networking(w3wp)\Connections Established" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Networking 4.0.0.0(w3wp)\Connections Established" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\.NET CLR Remoting(w3wp)\Remote Calls/sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET\Application Restarts" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET\Applications Running" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET\Requests Current" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET\Request Execution Time" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET\Requests Queued" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET\Requests Rejected" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET\Request Wait Time" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET\Requests Disconnected" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET\Worker Processes Running" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET\Worker Process Restarts" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET v4.0.30319\Application Restarts" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET v4.0.30319\Applications Running" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET v4.0.30319\Requests Current" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET v4.0.30319\Request Execution Time" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET v4.0.30319\Requests Queued" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET v4.0.30319\Requests Rejected" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET v4.0.30319\Request Wait Time" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET v4.0.30319\Requests Disconnected" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET v4.0.30319\Worker Processes Running" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET v4.0.30319\Worker Process Restarts" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Anonymous Requests" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Anonymous Requests/Sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Cache Total Entries" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Cache Total Turnover Rate" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Cache Total Hits" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Cache Total Misses" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Cache Total Hit Ratio" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Cache API Entries" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Cache API Turnover Rate" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Cache API Hits" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Cache API Misses" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Cache API Hit Ratio" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Output Cache Entries" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Output Cache Turnover Rate" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Output Cache Hits" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Output Cache Misses" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Output Cache Hit Ratio" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Compilations Total" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Debugging Requests" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Errors During Preprocessing" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Errors During Compilation" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Errors During Execution" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Errors Unhandled During Execution" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Errors Unhandled During Execution/Sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Errors Total" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Errors Total/Sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Pipeline Instance Count" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Request Bytes In Total" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Request Bytes Out Total" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Requests Executing" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Requests Failed" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Requests Not Found" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Requests Not Authorized" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Requests In Application Queue" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Requests Timed Out" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Requests Succeeded" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Requests Total" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Requests/Sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Sessions Active" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Sessions Abandoned" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Sessions Timed Out" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Sessions Total" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Transactions Aborted" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Transactions Committed" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Transactions Pending" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Transactions Total" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Applications(__Total__)\Transactions/Sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Anonymous Requests" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Anonymous Requests/Sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Cache Total Entries" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Cache Total Turnover Rate" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Cache Total Hits" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Cache Total Misses" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Cache Total Hit Ratio" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Cache API Entries" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Cache API Turnover Rate" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Cache API Hits" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Cache API Misses" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Cache API Hit Ratio" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Output Cache Entries" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Output Cache Turnover Rate" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Output Cache Hits" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Output Cache Misses" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Output Cache Hit Ratio" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Compilations Total" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Debugging Requests" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Errors During Preprocessing" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Errors During Compilation" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Errors During Execution" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Errors Unhandled During Execution" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Errors Unhandled During Execution/Sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Errors Total" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Errors Total/Sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Pipeline Instance Count" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Request Bytes In Total" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Request Bytes Out Total" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Requests Executing" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Requests Failed" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Requests Not Found" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Requests Not Authorized" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Requests In Application Queue" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Requests Timed Out" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Requests Succeeded" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Requests Total" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Requests/Sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Sessions Active" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Sessions Abandoned" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Sessions Timed Out" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Sessions Total" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Transactions Aborted" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Transactions Committed" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Transactions Pending" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Transactions Total" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\ASP.NET Apps v4.0.30319(__Total__)\Transactions/Sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Process(w3wp)\% Processor Time" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Process(w3wp)\Virtual Bytes" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Process(w3wp)\Private Bytes" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Process(w3wp)\Thread Count" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Process(w3wp)\Handle Count" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Web Service(_Total)\Bytes Total/sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Web Service(_Total)\Current Connections" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Web Service(_Total)\Total Method Requests/sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\Web Service(_Total)\ISAPI Extension Requests/sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\SQLServer:Buffer Manager\Page reads/sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\SQLServer:Buffer Manager\Page writes/sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\SQLServer:Buffer Manager\Checkpoint pages/sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\SQLServer:Buffer Manager\Lazy writes/sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\SQLServer:Buffer Manager\Buffer cache hit ratio" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\SQLServer:Buffer Manager\Database pages" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\SQLServer:Memory Manager\Total Server Memory (KB)" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\SQLServer:Memory Manager\Memory Grants Pending" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\SQLServer:General Statistics\User Connections" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\SQLServer:SQL Statistics\Batch Requests/sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\SQLServer:SQL Statistics\SQL Compilations/sec" sampleRate="PT60S" unit="Count"/><PerformanceCounterConfiguration counterSpecifier="\SQLServer:SQL Statistics\SQL Re-Compilations/sec" sampleRate="PT60S" unit="Count"/></PerformanceCounters>    <Metrics resourceId="'+$vmId+'">      <MetricAggregation scheduledTransferPeriod="PT1H"/>      <MetricAggregation scheduledTransferPeriod="PT1M"/>    </Metrics>    <WindowsEventLog scheduledTransferPeriod="PT1M">                      <DataSource name="Application!*[System[(Level=1 or Level=2)]]"/><DataSource name="System!*[System[(Level=1 or Level=2)]]"/></WindowsEventLog>  <EtwProviders/></DiagnosticMonitorConfiguration></WadCfg><StorageAccount>"'+$storagename+'"</StorageAccount>'

        $extensionTemplate = '{
  "StorageAccount": "'+$storagename+'",
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
            "counterSpecifier": "\\Processor Information(_Total)\\% Processor Time",
            "unit": "Percent",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Processor Information(_Total)\\% Privileged Time",
            "unit": "Percent",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Processor Information(_Total)\\% User Time",
            "unit": "Percent",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Processor Information(_Total)\\Processor Frequency",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\System\\Processes",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Process(_Total)\\Thread Count",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Process(_Total)\\Handle Count",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\System\\System Up Time",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\System\\Context Switches/sec",
            "unit": "CountPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\System\\Processor Queue Length",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
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
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\% Disk Time",
            "unit": "Percent",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\% Disk Read Time",
            "unit": "Percent",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\% Disk Write Time",
            "unit": "Percent",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\% Idle Time",
            "unit": "Percent",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Bytes/sec",
            "unit": "BytesPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Read Bytes/sec",
            "unit": "BytesPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Write Bytes/sec",
            "unit": "BytesPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Transfers/sec",
            "unit": "BytesPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Reads/sec",
            "unit": "BytesPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\Disk Writes/sec",
            "unit": "BytesPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk sec/Transfer",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk sec/Read",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk sec/Write",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk Queue Length",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk Read Queue Length",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\Avg. Disk Write Queue Length",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\% Free Space",
            "unit": "Percent",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\LogicalDisk(_Total)\\Free Megabytes",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Network Interface(*)\\Bytes Total/sec",
            "unit": "BytesPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Network Interface(*)\\Bytes Sent/sec",
            "unit": "BytesPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Network Interface(*)\\Bytes Received/sec",
            "unit": "BytesPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Network Interface(*)\\Packets/sec",
            "unit": "BytesPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Network Interface(*)\\Packets Sent/sec",
            "unit": "BytesPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Network Interface(*)\\Packets Received/sec",
            "unit": "BytesPerSecond",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Network Interface(*)\\Packets Outbound Errors",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Network Interface(*)\\Packets Received Errors",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Exceptions(w3wp)\\# of Exceps Thrown / sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Interop(w3wp)\\# of marshalling",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Jit(w3wp)\\% Time in Jit",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Loading(w3wp)\\Current appdomains",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Loading(w3wp)\\Current Assemblies",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Loading(w3wp)\\% Time Loading",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Loading(w3wp)\\Bytes in Loader Heap",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR LocksAndThreads(w3wp)\\Contention Rate / sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR LocksAndThreads(w3wp)\\Current Queue Length",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Memory(w3wp)\\# Gen 0 Collections",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Memory(w3wp)\\# Gen 1 Collections",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Memory(w3wp)\\# Gen 2 Collections",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Memory(w3wp)\\% Time in GC",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Memory(w3wp)\\# Bytes in all Heaps",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Networking(w3wp)\\Connections Established",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Networking 4.0.0.0(w3wp)\\Connections Established",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\.NET CLR Remoting(w3wp)\\Remote Calls/sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET\\Application Restarts",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET\\Applications Running",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET\\Requests Current",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET\\Request Execution Time",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET\\Requests Queued",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET\\Requests Rejected",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET\\Request Wait Time",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET\\Requests Disconnected",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET\\Worker Processes Running",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET\\Worker Process Restarts",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET v4.0.30319\\Application Restarts",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET v4.0.30319\\Applications Running",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET v4.0.30319\\Requests Current",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET v4.0.30319\\Request Execution Time",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET v4.0.30319\\Requests Queued",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET v4.0.30319\\Requests Rejected",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET v4.0.30319\\Request Wait Time",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET v4.0.30319\\Requests Disconnected",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET v4.0.30319\\Worker Processes Running",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET v4.0.30319\\Worker Process Restarts",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Anonymous Requests",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Anonymous Requests/Sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Cache Total Entries",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Cache Total Turnover Rate",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Cache Total Hits",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Cache Total Misses",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Cache Total Hit Ratio",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Cache API Entries",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Cache API Turnover Rate",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Cache API Hits",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Cache API Misses",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Cache API Hit Ratio",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Output Cache Entries",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Output Cache Turnover Rate",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Output Cache Hits",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Output Cache Misses",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Output Cache Hit Ratio",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Compilations Total",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Debugging Requests",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Errors During Preprocessing",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Errors During Compilation",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Errors During Execution",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Errors Unhandled During Execution",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Errors Unhandled During Execution/Sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Errors Total",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Errors Total/Sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Pipeline Instance Count",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Request Bytes In Total",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Request Bytes Out Total",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Requests Executing",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Requests Failed",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Requests Not Found",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Requests Not Authorized",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Requests In Application Queue",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Requests Timed Out",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Requests Succeeded",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Requests Total",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Requests/Sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Sessions Active",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Sessions Abandoned",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Sessions Timed Out",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Sessions Total",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Transactions Aborted",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Transactions Committed",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Transactions Pending",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Transactions Total",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Applications(__Total__)\\Transactions/Sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Anonymous Requests",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Anonymous Requests/Sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Cache Total Entries",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Cache Total Turnover Rate",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Cache Total Hits",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Cache Total Misses",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Cache Total Hit Ratio",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Cache API Entries",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Cache API Turnover Rate",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Cache API Hits",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Cache API Misses",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Cache API Hit Ratio",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Output Cache Entries",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Output Cache Turnover Rate",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Output Cache Hits",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Output Cache Misses",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Output Cache Hit Ratio",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Compilations Total",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Debugging Requests",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Errors During Preprocessing",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Errors During Compilation",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Errors During Execution",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Errors Unhandled During Execution",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Errors Unhandled During Execution/Sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Errors Total",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Errors Total/Sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Pipeline Instance Count",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Request Bytes In Total",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Request Bytes Out Total",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Requests Executing",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Requests Failed",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Requests Not Found",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Requests Not Authorized",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Requests In Application Queue",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Requests Timed Out",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Requests Succeeded",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Requests Total",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Requests/Sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Sessions Active",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Sessions Abandoned",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Sessions Timed Out",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Sessions Total",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Transactions Aborted",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Transactions Committed",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Transactions Pending",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Transactions Total",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\ASP.NET Apps v4.0.30319(__Total__)\\Transactions/Sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Process(w3wp)\\% Processor Time",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Process(w3wp)\\Virtual Bytes",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Process(w3wp)\\Private Bytes",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Process(w3wp)\\Thread Count",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Process(w3wp)\\Handle Count",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Web Service(_Total)\\Bytes Total/sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Web Service(_Total)\\Current Connections",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Web Service(_Total)\\Total Method Requests/sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\Web Service(_Total)\\ISAPI Extension Requests/sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\SQLServer:Buffer Manager\\Page reads/sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\SQLServer:Buffer Manager\\Page writes/sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\SQLServer:Buffer Manager\\Checkpoint pages/sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\SQLServer:Buffer Manager\\Lazy writes/sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\SQLServer:Buffer Manager\\Buffer cache hit ratio",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\SQLServer:Buffer Manager\\Database pages",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\SQLServer:Memory Manager\\Total Server Memory (KB)",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\SQLServer:Memory Manager\\Memory Grants Pending",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\SQLServer:General Statistics\\User Connections",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\SQLServer:SQL Statistics\\Batch Requests/sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\SQLServer:SQL Statistics\\SQL Compilations/sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          },
          {
            "counterSpecifier": "\\SQLServer:SQL Statistics\\SQL Re-Compilations/sec",
            "unit": "Count",
            "sampleRate": "PT60S"
          }
        ]
      },
      "WindowsEventLog": {
        "scheduledTransferPeriod": "PT1M",
        "DataSource": [
          {
            "name": "Application!*[System[(Level=1 or Level=2 or Level=3)]]"
          },
          {
            "name": "System!*[System[(Level=1 or Level=2 or Level=3)]]"
          }
        ]
      },
      "Directories": {
        "scheduledTransferPeriod": "PT1M"
      }
    }
  }
}'
    
    $xmlCfgPath =Join-Path $deployExtensionLogDir "windowsxmlcfg.xml";

    Out-File -FilePath $xmlCfgPath -force -Encoding utf8 -InputObject $extensiontemplatewin

    $encodingXmlCfg =  [System.Convert]::ToBase64String([system.Text.Encoding]::UTF8.GetBytes($extensiontemplatewin));

    $extensionTemplatePath = Join-Path $deployExtensionLogDir "extensionTemplateForWindows.json";
    Out-File -FilePath $extensionTemplatePath -Force -Encoding utf8 -InputObject $extensionTemplate
    
    
    $extensionPublisher = 'Microsoft.Azure.Diagnostics'
    $extensionVersion = "1.5"
    ##"storageAccountKey": "'+$storageKey+'"
    Set-AzureRmVMExtension -ResourceGroupName $rsgName -VMName $vmName -Name $extensionName -ExtensionType $extensionType -Publisher $extensionPublisher -TypeHandlerVersion $extensionVersion -Settingstring $extensionTemplate -ProtectedSettingString $privateCfg -Location $vmLocation -AsJob
    ##New-AzureRmResourceGroupDeployment -ResourceGroupName $rsgName -TemplateFile $extensionTemplatePath
    ##Set-AzureRmVMDiagnosticsExtension -ResourceGroupName $rsgName -VMName $vmName -StorageAccountName $storageName -StorageAccountKey $storageKey -Name $extensionName -Location $vmLocation -DiagnosticsConfigurationPath $xmlCfgPath -AutoUpgradeMinorVersion $True
    ####Set-AzureRmVMDiagnosticsExtension -ResourceGroupName $rsgName -VMName $vmName -StorageAccountName $storageName -StorageAccountKey $storageKey -Name $extensionName -Location $vmLocation -DiagnosticsConfigurationPath $extensionTemplatePath -AutoUpgradeMinorVersion $True
}

$deployExtensionLogDir = split-path -parent $MyInvocation.MyCommand.Definition

if($subscriptionId){
    Login-AzureRmAccount -SubscriptionId $subscriptionId -ErrorAction Stop
    $getsub = get-azurermsubscription
    $subname = $getsub.Name
    $storagersgName = Get-AzureRmStorageAccount | where {$_.StorageAccountName -eq $storageaccount} | Select-Object -ExpandProperty ResourceGroupName
    #save-azurermcontext -Path .\context_$TimeStamp.json
    $startdate = [system.datetime]::now.AddDays(-1)
    $enddate = [system.datetime]::Now.AddYears(999)
    $storageKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $StoragersgName -Name $storageName;
    $storageKey = $storageKeys[0].Value;
    $context = new-azurestoragecontext -StorageAccountName $storageAccount -StorageAccountKey $storageKey
    $storageSas = new-azurestorageaccountsastoken -Service Blob,Table -ResourceType Container,Object -Permission wlacu -Context $context -StartTime $startdate -ExpiryTime $enddate
    $privateCfg = '{
    "storageAccountName": "'+$storageName+'",
    "storageAccountSasToken": "'+$storageSas+'"
    }'
} else {
    Login-AzureRmAccount -ErrorAction Stop
}

$vmList = $null
if($vmname -and $storageaccount){
    Write-Host "Selected Resource Group: " $resourcegroup " VM Name:" $vmname
    #$vmList = Get-AzureRmVM -Name $vmname -ResourceGroupName $resourcegroup
    $vmList = Get-AzureRmVM -Name $vmname
    Add-Content -Path .\InstallLog_$TimeStampLog.csv -Value 'Subscription Name,VM Name,OS Type,Errors'
} 
elseif($storageaccount) {
    #$vmList = Get-AzureRmVM -ResourceGroupName $resourcegroup
    $vmList = Get-AzureRmVM
    Add-Content -Path .\InstallLog_$TimeStampLog.csv -Value 'Subscription Name,VM Name,OS Type,Errors'
    }


if($vmList){
    foreach($vm in $vmList){
        $status=$vm | Get-AzureRmVM -Status $vm.ResourceGroupName
        if ($status.Statuses[1].DisplayStatus -ne "VM running")
        {
            Write-Host $vm.Name" is not running. Skipping install." 
            $vmName = $vm.Name
            Add-Content -Path .\InstallLog_$TimeStampLog.csv -Value "'$subname,$vmname,Not Running,Error VM Not Running power on VM and run again'"
           
            continue 
        }
        $rsgName = $vm.ResourceGroupName;
        $rsg = Get-AzureRmResourceGroup -Name $rsgName
        $rsgLocation = $vm.Location;
        
        $storageName = $storageaccount

        $vmId = $vm.Id
        $vmName = $vm.Name
        Write-Host "VM ID:" $vmId 
        Write-Host "VM Name:" $vmName 

        $osType = $vm.StorageProfile.OsDisk.OsType
        Write-Host "OS Type:" $osType

        if($osType -eq 0){
            Write-Host "VM Type Detected is Windows"
            $error.clear()
            InstallWindowsExtension -rsgName $rsgName -rsgLocation $rsgLocation -vmId $vmId -vmName $vmName
            Add-Content -Path .\InstallLog_$TimeStampLog.csv -Value "'$subname,$vmName,Windows,$error'"
        } else {
            Write-Host "VM Type Detected is Linux "
            $error.clear()
            InstallLinuxExtension -rsgName $rsgName -rsgLocation $rsgLocation -vmId $vmId -vmName $vmName
            Add-Content -Path .\InstallLog_$TimeStampLog.csv -Value "'$subname,$vmName,Linux,$error'"
        }
    }
} else {
    Write-Host "Couldn't find any VMs on your account"
    Write-Output "Couldn't find any VMs on your account" | Out-File -FilePath .\NoVMs_$TimeStampLog.csv
    
}
