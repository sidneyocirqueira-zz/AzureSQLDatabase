CREATE USER [usrAzureSQLMaintenance] WITH PASSWORD = 'coloqueaquisuasenha'
GO 
GRANT EXEC ON SCHEMA::monitoramento TO [usrAzureSQLMaintenance]
GO
GRANT VIEW DATABASE STATE  TO [usrAzureSQLMaintenance]
