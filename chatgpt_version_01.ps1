$GetItemsProperties = @{
    Sources = @(
        @{"C:\Users\abrah\Desktop" = @{}}
    )
    Destination = ""
    Limit = @{
        ItemSize = @{
            Enable = $false
            Bytes = 1000000000
        }
        ItemType = @{
            Enable = $false
            ExtensionsList = @(".pdf", ".csv", ".docx", ".zip")
        }
        Exclude = @{
            Enable = $true
            ExclusionList = @("C:\LocalRepo\PowerShellPlayGround")
        }
    }
    DeveloperOptions = @{
        FeedBack = @{
            Enable = $true
        }
    }
}

Function Get-Items {
    param([hashtable]$GetItemsProperties)

    $results = @{}

    foreach ($directory in $GetItemsProperties.Sources) {
        $key = [string]($directory.Keys)
        $items = Get-ChildItem -Path $key -Recurse

        # Filter out specific items by full path
        if ($GetItemsProperties.Limit.Exclude.Enable) {
            foreach ($excludedItem in $GetItemsProperties.Limit.Exclude.ExclusionList) {
                $items = $items | Where-Object { $_.FullName -notlike $excludedItem }
            }
        }

        # Filter out items by extension type
        if ($GetItemsProperties.Limit.ItemType.Enable) {
            $items = $items | Where-Object { $GetItemsProperties.Limit.ItemType.ExtensionsList -notcontains $_.Extension }
        }

        # Filter out items by size
        if ($GetItemsProperties.Limit.ItemSize.Enable) {
            $items = $items | Where-Object { $_.Length -lt $GetItemsProperties.Limit.ItemSize.Bytes }
        }

        $directory[$key] = @{
            Folders = @()
            Files = @()
            Properties = @{
                TotalSizeBytes = 0
                TotalFiles = 0
                TotalFolders = 0
                TotalItems = 0
            }
        }

        foreach ($item in $items) {
            if ($item.PSIsContainer) {
                $directory[$key].Folders += [pscustomobject]@{
                    FullName = $item.FullName
                    BaseName = $item.BaseName
                }
                $directory[$key].Properties.TotalFolders++
            } else {
                $directory[$key].Files += [pscustomobject]@{
                    FullName = $item.FullName
                    BaseName = $item.BaseName
                    Extension = $item.Extension
                    LastWriteTime = $item.LastWriteTime
                    SizeBytes = $item.Length
                }
                $directory[$key].Properties.TotalSizeBytes += $item.Length
                $directory[$key].Properties.TotalFiles++
            }
        }

        $directory[$key].Properties.TotalItems = $directory[$key].Properties.TotalFolders + $directory[$key].Properties.TotalFiles
        $results[$key] = $directory[$key]

        if ($GetItemsProperties.DeveloperOptions.FeedBack.Enable) {
            $feedback = "+- [{0}] - {1}" -f "parent dir", $key
            Write-Host "$($directory[$key].Properties.TotalItems)" -ForegroundColor Yellow
            Write-Host $feedback -ForegroundColor Cyan
        }

        # Recursive call for subdirectories
        foreach ($subdirectory in $directory[$key].Folders) {
            $GetItemsProperties.Sources = @{ @{($subdirectory.FullName) = @{}} }
            $results += Get-Items $GetItemsProperties
        }
    }

    return $results
}

# Example usage
$items = Get-Items -GetItemsProperties $GetItemsProperties

$hold = @()
foreach ($result in $items) {
    $hold += $result
}

foreach ($i in 0..(($hold.count) - 1)) {
    $hold[$i].KEYS
    $hold[$i].VALUES.Properties
}
