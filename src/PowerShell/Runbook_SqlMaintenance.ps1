$AzureSQLServerName = "informe aqui o servername"
$AzureSQLDatabaseName = "informe aqui a database"
 
$AzureSQLServerName = $AzureSQLServerName + ".database.windows.net"
$Cred = Get-AutomationPSCredential -Name "informe aqui a credential do automation que conecta no banco de dados"
$SQLOutput = $(Invoke-Sqlcmd -ServerInstance $AzureSQLServerName -Username $Cred.UserName -Password $Cred.GetNetworkCredential().Password -Database $AzureSQLDatabaseName -Query "exec [dbo].[AzureSQLMaintenance] @Operation='all' ,@LogToTable=1" -QueryTimeout 65535 -ConnectionTimeout 60 -Verbose) 4>&1
 
Write-Output $SQLOutput
