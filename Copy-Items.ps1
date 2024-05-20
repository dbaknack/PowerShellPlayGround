

param([hashtable]$GetItemsProperties)


$GetItemsProperties = @{
    Sources = @(
        @{ Path = "C:\LocalRepo\PowerShellPlayGround" }
        @{ Path = "C:\Users\abrah\Documents\test_destination"}
    )

    Destination = "C:\Users\abrah\Documents\test_destination"
    Limit = @{
        ItemSize = @{
            Enable = $false
            Bytes = 1000000000
        }
        ItemType = @{
            Enable = $false
            ExtensionsList = @(
                ".pdf"
                ".csv"
                ".docx"
                ".zip"
            )
        }
        Exclude = @{
            Enable = $true
            ExclusionList = @(
                "C:\LocalRepo_2\PSUTILITIES\Test"
                "C:\LocalRepo_2\PSSTIG\Public"
            )
        }
    }
    DeveloperOptions = @{
        FeedBack = @{
            Enable = $true
        }
    }
}
function Copy-FileWithBuffer {
    param (
        [string]$sourcePath,
        [string]$destinationPath,
        [int]$bufferSize
    )

    try {
        $sourceStream = [System.IO.File]::OpenRead($sourcePath)
        $destinationStream = [System.IO.File]::Create($destinationPath)

        $buffer = New-Object byte[] $bufferSize
        $bytesRead = 0

        while (($bytesRead = $sourceStream.Read($buffer, 0, $bufferSize)) -gt 0) {
            $destinationStream.Write($buffer, 0, $bytesRead)
        }

        $sourceStream.Close()
        $destinationStream.Close()

        Write-Host "Copied file: $sourcePath to $destinationPath"
    } catch {
        Write-Error "Failed to copy file: $sourcePath to $destinationPath. Error: $_"
    }
}
function Get-Items {
    param([hashtable]$GetItemsProperties)
    begin{

        $globalDestination = $GetItemsProperties.Destination
        if($GetItemsProperties.DeveloperOptions.FeedBack.Enable){
            $feedBack = "| {0}" -f "Running check(s)"
            Write-Host $feedBack -ForegroundColor Yellow
        }
        

        # the destination should always be reachable
        $destinationReachable = $true
        if(-not(Test-Path -Path $globalDestination)){
            $msgError = ("[{0}]:: {1}" -f "Destination validation","Cannot find path '$($globalDestination)'")
            $destinationReachable = $false
            Write-Error $msgError -ErrorAction Stop
        }
        if(($destinationReachable) -and ($GetItemsProperties.DeveloperOptions.FeedBack.Enable)){
            $feedBack = "+- | {0}" -f "Destination validation"
            Write-Host $feedBack -ForegroundColor Yellow
            $feedBack = "|  +- '{0}' is reachable" -f ,$globalDestination
            Write-Host $feedBack -ForegroundColor Yellow
        }

        # all sources need to be resolved and filtered out of any leaf level wildcards
        if($GetItemsProperties.DeveloperOptions.FeedBack.Enable){
            $feedBack = "|"
            Write-Host $feedBack -ForegroundColor Yellow 
        }

        if($GetItemsProperties.DeveloperOptions.FeedBack.Enable){
            $feedBack = "+- | {0}" -f "Resolving source path"
            Write-Host $feedBack -ForegroundColor Yellow
        }
        foreach($source in $GetItemsProperties.Sources){
            if($source['Path']  -match '.*\*$'){
                $msgError = ("[{0}]:: {1}" -f "Source path structure","Leaf is not allowed to be a wildcard '$($sourcePath)'.")
                Write-Error $msgError -ErrorAction Stop
            }
            $source['Path'] = (Resolve-Path -path $source['Path']).Path

            if($GetItemsProperties.DeveloperOptions.FeedBack.Enable){
                $feedBack = "|  +- '{0}' resolved" -f ,$source['Path']
                Write-Host $feedBack -ForegroundColor Yellow
            }
        }

        # when the sources include the destination, the destination is removed from sources
        if($GetItemsProperties.DeveloperOptions.FeedBack.Enable){
            $feedBack = "|"
            Write-Host $feedBack -ForegroundColor Yellow 
        }
        $destinationFilteredOut = $false
        if($GetItemsProperties.Sources.path -contains $globalDestination){
            $destinationFilteredOut = $true
            $GetItemsProperties.Sources = $GetItemsProperties.Sources | Where-Object {$_.path -ne $globalDestination}
        }

        if($GetItemsProperties.DeveloperOptions.FeedBack.Enable){
            if($destinationFilteredOut){
                $feedBack = "+- | {0}" -f "Removing destination address from source path(s)"
            }

            if(-not($destinationFilteredOut)){
                $feedBack = "+- | {0}" -f "Destination address not in source path(s)"
            }
            Write-Host $feedBack -ForegroundColor Yellow
        }

        
        # all sources should be reachable
        if($GetItemsProperties.DeveloperOptions.FeedBack.Enable){
            $feedBack = "+- | {0}" -f "Testing Sources are reachable"
            Write-Host $feedBack -ForegroundColor Yellow
        }
        foreach($source in $GetItemsProperties.Sources){
            if(-not(Test-Path -Path ($source['Path']))){
                $msgError = ("[{0}]:: {1}" -f "Source validation","Cannot find path '$(($source['Path']).Path)'")
                Write-Error $msgError -ErrorAction Stop
            }

            if($GetItemsProperties.DeveloperOptions.FeedBack.Enable){
                $feedBack = "|  +- {0} {1}" -f $source['Path'], "is reachable"
                Write-Host $feedBack -ForegroundColor Yellow
            }
        }

        if($GetItemsProperties.DeveloperOptions.FeedBack.Enable){
            $feedBack = "|"
            Write-Host $feedBack -ForegroundColor Yellow
            $feedBack   = "+- COMPLETE"
            Write-Host $feedBack -ForegroundColor Yellow
        }
   }
   process{
        foreach ($source in $GetItemsProperties.Sources){
    
            $path = $source.Path
            $items = Get-ChildItem -Path $path
            
            # Filter out specific items by full path
            if ($GetItemsProperties.Limit.Exclude.Enable) {
                $excludedPaths = $GetItemsProperties.Limit.Exclude.ExclusionList
                $items = $items | Where-Object { $excludedPaths -notcontains $_.FullName }
            }
    
            # Filter out items by extension type
            if ($GetItemsProperties.Limit.ItemType.Enable) {
                $extensionsList = $GetItemsProperties.Limit.ItemType.ExtensionsList
                $items = $items | Where-Object { $extensionsList -notcontains $_.Extension }
            }
    
            # Filter out items by size
            if ($GetItemsProperties.Limit.ItemSize.Enable) {
                $maxSize = $GetItemsProperties.Limit.ItemSize.Bytes
                $items = $items | Where-Object { $_.Length -lt $maxSize }
            }
    
            $sourceData = @{
                Folders = @()
                Files   = @()
                Properties = @{
                    TotalSizeBytes  = 0
                    TotalFiles      = 0
                    TotalFolders    = 0
                    TotalItems      = 0
                }
            }
    
            foreach ($item in $items) {
                if ($item.PSIsContainer) {
                    $sourceData.Folders += [pscustomobject]@{
                        FullName = $item.FullName
                        BaseName = $item.BaseName
                    }
                    $sourceData.Properties.TotalFolders++
                } else {
                    $sourceData.Files += [pscustomobject]@{
                        FullName = $item.FullName
                        BaseName = $item.BaseName
                        Extension = $item.Extension
                        LastWriteTime = $item.LastWriteTime
                        SizeBytes = $item.Length
                    }
                    $sourceData.Properties.TotalSizeBytes += $item.Length
                    $sourceData.Properties.TotalFiles++
                }

                $item.DirectoryName
            }
    
            $sourceData.Properties.TotalItems = $sourceData.Properties.TotalFolders + $sourceData.Properties.TotalFiles
            $source[$path] = $sourceData
    
    
            if ($GetItemsProperties.DeveloperOptions.FeedBack.Enable) {
                $feedback = "+- | {0} - {1}" -f "Directory", $path
                Write-Host $feedback -ForegroundColor Cyan
                $feedback = "|"
                Write-Host $feedback -ForegroundColor Cyan
                $feedback = "+- | {0}" -f "Properties"
                Write-Host $feedback -ForegroundColor Cyan
                $feedback = "|  +- {0}: {1}" -f "Total bytes at this location",$sourceData.Properties.TotalSizeBytes
                Write-Host $feedback -ForegroundColor Cyan
                $feedback = "|  +- {0}: {1}" -f "Total folders at this location",$sourceData.Properties.TotalFolders
                Write-Host $feedback -ForegroundColor Cyan
                $feedback = "|  +- {0}: {1}" -f "Total files at this location",$sourceData.Properties.TotalFiles
                Write-Host $feedback -ForegroundColor Cyan
                $feedback = "|  |"
                Write-Host $feedback -ForegroundColor Cyan
                $feedback = "|  +- COMPLETE"
                Write-Host $feedback -ForegroundColor Cyan
                $feedback = "|"
                Write-Host $feedback -ForegroundColor Cyan
                $feedback = "+- COMPLETE"
                Write-Host $feedback -ForegroundColor Cyan
            }
            write-output $GetItemsProperties.Sources
            # Recursive call to process subdirectories
            foreach ($subdirectory in $sourceData.Folders) {
                $GetItemsProperties.Sources = @(@{ Path = $subdirectory.FullName })
                Get-Items -GetItemsProperties $GetItemsProperties
            }
        }
    }
}

$directories = Get-Items $GetItemsProperties

foreach($dir in $directories){
    Write-host $dir.Path -ForegroundColor Cyan
    $dir.($dir.Path).Folders
}
# Define buffer size (e.g., 4KB)

$GetItemsProperties.destination
foreach($dir in $directories){
$childDestinationFolder = Join-Path -Path $GetItemsProperties.Destination -ChildPath (Split-Path -Path $dir.Path -Leaf)
$childDestinationFolder
    if (-not (Test-Path -Path $childDestinationFolder)) {
        New-Item -Path $childDestinationFolder -ItemType Directory | Out-Null
    }
}
$bufferSize = 4096
$sourceData.Folders 
      # Copy files to the destination
      foreach ($folder in $sourceData.Folders) {
        $destinationFolderPath = Join-Path -Path $GetItemsProperties.Destination -ChildPath ($folder.BaseName)


        # Ensure the destination directory exists
        if (-not (Test-Path -Path $destinationFolderPath)) {
            New-Item -Path $destinationFolderPath -ItemType Directory -Force
        }
        # Copy the file with buffer
       # Copy-FileWithBuffer -sourcePath $file.FullName -destinationPath $destinationFilePath -bufferSize $bufferSize
    }

    foreach($file in $sourceData.Files){
        $destinationFolderPath
        $file
    }



$directories.keys
$directories[0].values
$directories[-2]