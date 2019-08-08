CREATE USER [usrAzureSQLMaintenance] WITH PASSWORD = 'PCsAH9EutTDmHZzp'
GO 
GRANT EXEC ON SCHEMA::monitoramento TO [usrAzureSQLMaintenance]
GO
GRANT VIEW DATABASE STATE  TO [usrAzureSQLMaintenance]