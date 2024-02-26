Function Invoke-UDFSQLCommand{
    param(
        [hashtable]$Query_Params
    )

    $processname = 'Invoke-UDFSQLCommand'
    $myQuery = "{0}" -f $Query_Params.Query
    $sqlconnectionstring = "
        server                          = $($Query_Params.InstanceName);
        database                        = $($Query_Params.DatabaseName);
        trusted_connection              = true;
        application name                = $processname;"
    # sql connection, setup call
    $sqlconnection                  = new-object system.data.sqlclient.sqlconnection
    $sqlconnection.connectionstring = $sqlconnectionstring
    $sqlconnection.open()
    $sqlcommand                     = new-object system.data.sqlclient.sqlcommand
    $sqlcommand.connection          = $sqlconnection
    $sqlcommand.commandtext         = $myQuery
    # sql connection, handle returned results
    $sqladapter                     = new-object system.data.sqlclient.sqldataadapter
    $sqladapter.selectcommand       = $sqlcommand
    $dataset                        = new-object system.data.dataset
    $sqladapter.fill($dataset) | out-null
    $resultsreturned                = $null
    $resultsreturned               += $dataset.tables
    $sqlconnection.close()      # the session opens, but it will not close as expected
    $sqlconnection.dispose()    # TO-DO: make sure the connection does close
    $resultsreturned.Rows
}
Function Invoke-PSSQL{
    param([hashtable]$Params)

    try{
        $SQLScript  = (Get-Content -Path (Get-ChildItem -path $Params.SQLScriptFolder -Filter "$($Params.SQLScriptFile).sql").FullName) -join "`n"
        $Params.ConnectionParams.Add("Query",$SQLScript)
    }catch{
        $Error[0] ; break
    }
    
    $InvokeParams = @{
        Session         = $Params.Session
        ArgumentList    = @{
            Func        = ${Function:Invoke-UDFSQLCommand}
            FuncParams  = $Params.ConnectionParams
        }
        ScriptBlock     = {
            param($ArgumentList)
            $ScriptBlock    = [scriptblock]::Create($ArgumentList.Func)
            $ArgumentList   = $ArgumentList.FuncParams
            Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList $ArgumentList
        }
    }
    Invoke-Command @InvokeParams | select-object -Property * -ExcludeProperty "RunSpaceID"
}