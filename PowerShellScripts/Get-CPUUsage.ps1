$COUNTER_PARAMS = @{
    ENCLAVE         = "DEVLAB"
    OutPutDirectory = "C:\LocalRepo"
    File            = "CPUUsage"
    Schema          = [ordered]@{
        RecID               = [int]
        Enclave             = [string]
        DomainName          = [string]
        HostName            = [string]
        DateTimeCollected   = [string]
        CPUUsagePercentance = [decimal]
    }
    Limit = @{
        DateTimeCollected   = -90
        SizeMB              = 50MB
    }
}

Function Get-AvgCPUUsage {
    param([hashtable]$getAvgCPUUsageParams)

    $avg     = (((Get-CimInstance win32_processor).LoadPercentage | Measure-Object -Average ).Average)
    $rounded = [math]::Ceiling($avg * 10)/10
    $rounded = [decimal]("{0:N2}" -f $rounded)
    
    $item = [ordered]@{
        Enclave             = $getAvgCPUUsageParams.Enclave
        DomainName          = $env:USERDNSDOMAIN
        HostName            = [System.Environment]::MachineName
        DateTimeCollected   = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
        CPUUsagePercentance = $rounded
    }
    return (New-Object -TypeName 'psobject' -Property $item)
}
Function New-CPUEntry {
    param([hashtable]$newCPUEntryParams)

    $outPutFile = "{0}\{1}.csv" -f $newCPUEntryParams.OutPutDirectory,$newCPUEntryParams.File

    # create the csv if it doesn't already exists
    if(-not(test-path -Path $outPutFile)){
        New-Item -Path $outPutFile | Out-Null
    }

    $file = @{
        Path = $outPutFile
    }

    $file.Add("Item",(Get-Item -path $file.Path))

    # initalize
    if($file.Item.Length -eq 0){
        $headers = '"'+(@($newCPUEntryParams.data.schema.keys) -join ('","'))+'"'
        Set-Content -Path $file.Path -Value $headers
        $file.Item = (Get-Item -path $file.Path)
    }

    # size check
    if(($file.Item.Length) -gt $newCPUEntryParams.data.Limit.SizeMB){
        Set-Content -Path $file.Path -Value $null
    }

    $file.Add("Data",((get-content -Path $file.Item.FullName) | ConvertFrom-Csv))

    $RecID          = [int]
    $compPropRecId  = @{Name = "RecID"; expression = {$RecID}}

    $lastEntry  = $file.Data | Select-Object  -Last 1
    $firstEntry = $file.Data | Select-Object  -First 1

    # get record count
    if((($file.Data | Measure-Object).Count ) -eq 0){
        $RecID = 1
    }else{
        $RecID = ([int]($lastEntry).RecID) + 1
    }

    $entry      = @()
    $valuesList = @()

    if($RecID -eq 1){
        $entry += $newCPUEntryParams.Object | Select-Object -Property $compPropRecId,*
        Set-Content -Path $file.Path -Value ($entry | ConvertTo-Csv -NoTypeInformation)
    }else{
        if(([DateTime]::ParseExact(
            ($firstEntry.DateTimeCollected),
            "yyyy-MM-dd HH:mm:ss.fff",
            [System.Globalization.CultureInfo]::InvariantCulture
        )) -lt (Get-Date).AddDays($newCPUEntryParams.data.Limit.DateTimeCollected)){
            $entry += ($file.Data | Select-Object -skip 1)
            $entry += $newCPUEntryParams.Object  | Select-Object -Property $compPropRecId,*
            Set-Content -Path $file.Path -Value ($entry | ConvertTo-Csv -NoTypeInformation)
        }else{
            $entry = $newCPUEntryParams.Object | Select-Object -Property $compPropRecId,*
            foreach($key in $newCPUEntryParams.data.schema.keys){
                $valuesList += $entry.$key
            }
            $valuesList = '"'+($valuesList -join '","')+'"'
            Add-Content -Path $file.Path -Value $valuesList 
        }
    }
}

New-CPUEntry @{
    OutPutDirectory = $COUNTER_PARAMS.OutPutDirectory
    File            = $COUNTER_PARAMS.File
    Object          = (Get-AvgCPUUsage @{Enclave = $COUNTER_PARAMS.ENCLAVE})
    data            = @{
        schema = $COUNTER_PARAMS.Schema
        Limit = $COUNTER_PARAMS.Limit
    }
}
