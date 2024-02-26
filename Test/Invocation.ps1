
Import-Module ./PSCONNECT; 
. ./POWERSHELLPLAYGROUND/Private/PSSQL.PS1
. ./POWERSHELLPLAYGROUND/Private/PSCMD.PS1

$PSCONNECT = PSCONNECT
$PSCONNECT.GetHostData(@{All = $true}) | Format-Table -AutoSize
$PSCONNECT.StashCredentials(@{CredentialAlias = "DEV-ADM" ; Credentials = (Get-Credential)})
$PSCONNECT.CreateRemoteSession(@{Use = "Alias"}) ; $Sessions = Get-PSSession

$PSSQLParams = @{
    DEVSQL01 = @{
        SQLScriptFolder =  "./POWERSHELLPLAYGROUND/SQLScripts";
        Session         = $Sessions[0]
        Script          = "Version";
        InstanceName    = "DEV-SQL01\SANDBOX01";
        DatabaseName    = "Master"
    }
    # DEVSQPLT01 = @{
    #     SQLScriptFolder =  "./POWERSHELLPLAYGROUND/SQLScripts";
    #     Session         = $Sessions[1]
    #     Script          = "Version";
    #     InstanceName    = "DEV-SPLT01\INST01";
    #     DatabaseName    = "Master"
    # }
}
$SQLResult = @()
foreach($hostName in $PSSQLParams.keys){
    $SQLResult += Invoke-PSSQL @{
        Session             =   $PSSQLParams.$hostName.Session
        SQLScriptFolder     =   $PSSQLParams.$hostName.SQLScriptFolder
        SQLScriptFile       =   $PSSQLParams.$hostName.Script
        ConnectionParams    = @{
            InstanceName    =   $PSSQLParams.$hostName.InstanceName
            DatabaseName    =   $PSSQLParams.$hostName.DatabaseName
        }
    }
}

Invoke-UDFSQLCommand @{
    InstanceName = 'DEV-SPLT01\INST01'
    DatabaseName = 'Master'
    Query = 'SELECT @@Version'
}
$SQLResult | ft -a

# here we pass in a list of sessions in to run a given command, with a set of parameters
Invoke-PSCMD @{
    Session                 = $Sessions
    PowerShellScriptFolder  = "./POWERSHELLPLAYGROUND/PowerShellScripts"
    PowerShellScriptFile    = "GetFolders"
    ArgumentList            = @("C:\")
    AsJob                   = $true
}
$results = Get-Job | Receive-Job -Wait  | Group-Object -Property "pscomputerName" -AsHashTable ; Get-Job | Remove-Job
$results.Values

# here we pass in one session with a set of parameters
Invoke-PSCMD @{
    Session                 = @($Sessions[1])
    PowerShellScriptFolder  = "./POWERSHELLPLAYGROUND/PowerShellScripts"
    PowerShellScriptFile    = "GetFolders"
    ArgumentList            = @("C:\")
    AsJob                   = $true
}
$results = Get-Job | Receive-Job -Wait  | Group-Object -Property "pscomputerName" -AsHashTable ; Get-Job | Remove-Job
$results.values

# here we pass is a session, but not as a job
$results = Invoke-PSCMD @{
    Session                 = @($Sessions[1])
    PowerShellScriptFolder  = "./POWERSHELLPLAYGROUND/PowerShellScripts"
    PowerShellScriptFile    = "GetFolders"
    ArgumentList            = @("C:\")
    AsJob                   = $false
};$results