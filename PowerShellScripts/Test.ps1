param(
    [hashtable]$Sources,
    [string]$Destination
)

$Sources = @(
    @{"/Users/alexhernandez/LocalRepo" = @{}}
)
$Destination = "/Users/alexhernandez/LocalRepo/File/Test_destination"

Function Get-Items {
    param([array]$Sources,[string]$Destination)

    foreach($directory in $Sources){
        $key = [string]($directory.Keys)
        
        $items = Get-ChildItem -path $key 
        $directory[$key] +=@{
            Folders = @()
            Files   = @()
            Properties = @{
                TotalSizeBytes  = 0
                TotalFiles      = 0
                TotalFolders    = 0
                TotalItems      = 0
            }
        }
        foreach($item in $items){
            switch($item.PSIsContainer){
                $true   {
                    $directory[$key].Folders += [pscustomobject]@{
                        FullName = $item.FullName
                        BaseName = $item.BaseName
                    }
                    $directory[$key].Properties.TotalFolders = $directory[$key].Properties.TotalFolders + 1
                }
                $false  {
                    $directory[$key].Files   += [pscustomobject]@{
                        FullName        = $item.FullName
                        BaseName        = $item.BaseName
                        Extension       = $item.Extension
                        LastWriteTime   = $item.LastWriteTime
                        SizeBytes       = $item.Length
                    }
                    $directory[$key].Properties.TotalSizeBytes  = ($directory[$key].Properties.TotalSizeBytes + $item.Length)
                    $directory[$key].Properties.TotalFiles      = $directory[$key].Properties.TotalFiles + 1
                }
            }
        }
        $directory[$key].Properties.TotalItems = $directory[$key].Properties.TotalFolders + $directory[$key].Properties.TotalFiles
    }

    Write-host $key -ForegroundColor cyan
    foreach($subdirectory in $directory[$key].Folders){
        Get-Items @(@{$subdirectory.FullName = @{}})
    }
    return $directory
}

Function Copy-Items{

}
$results = (Get-Items $Sources)


foreach($parent in $results){
    $key = $parent.Keys
    $parent[$key].Properties.TotalSizeBytes
}