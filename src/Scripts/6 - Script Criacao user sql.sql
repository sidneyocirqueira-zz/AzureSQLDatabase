CREATE USER [usrAzureSQLMaintenance] WITH PASSWORD = 'coloqueaquisuasenha'
GO 
GRANT EXEC ON SCHEMA::monitoramento TO [usrAzureSQLMaintenance]
GO
GRANT CONTROL ON DATABASE ::WIZCRM TO [usrAzureSQLMaintenance]
GO
GRANT ALTER ON DATABASE ::WIZCRM TO [usrAzureSQLMaintenance]
