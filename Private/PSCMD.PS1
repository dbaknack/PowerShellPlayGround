Function Invoke-PSCMD{
    param([hashtable]$Params)
    begin{
        try{
            $PwshScript = (Get-Content -path (Get-ChildItem -path $Params.PowerShellScriptFolder -Filter "$($Params.PowerShellScriptFile).ps1").FullName) -join "`n"
        }catch{
            $Error[0]
        }
    }
    process{
        $results = $null
        foreach($Session in $Params.Session){
            $InvokeParams   = @{
                Session         = $Session
                ArgumentList    = @{
                    Func        = $PwshScript
                    FuncParams  = $Params.ArgumentList
                }
                ScriptBlock     = {
                    param($ArgumentList)
                    $ScriptBlock    = [scriptblock]::Create($ArgumentList.Func)
                    $ArgumentList   = $ArgumentList.FuncParams
                    Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
                }
            }

            $results = switch($Params.AsJob){
                $true   {
                    (Invoke-Command @InvokeParams -AsJob | Out-Null)
                }
                $false  {
                    (Invoke-Command @InvokeParams)
                    }
            }
        }
    }
    end{
        return $results
    }
}