$AzureSQLServerName = "bancoscorporativos"
$AzureSQLDatabaseName = "parceirosdb"
 
$AzureSQLServerName = $AzureSQLServerName + ".database.windows.net"
$Cred = Get-AutomationPSCredential -Name "SQLLogin"
$SQLOutput = $(Invoke-Sqlcmd -ServerInstance $AzureSQLServerName -Username $Cred.UserName -Password $Cred.GetNetworkCredential().Password -Database $AzureSQLDatabaseName -Query "exec [dbo].[AzureSQLMaintenance] @Operation='all' ,@LogToTable=1" -QueryTimeout 65535 -ConnectionTimeout 60 -Verbose) 4>&1
 
Write-Output $SQLOutput