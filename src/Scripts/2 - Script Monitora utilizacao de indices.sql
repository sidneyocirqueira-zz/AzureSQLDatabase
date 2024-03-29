
/* STEP 2 - ROTINA DE UTILIZAÇÃO DE INDICES - DONE */

----------------------------- HISTORICO UTILIZACAO DE INDICE

-- Criar as tabelas abaixo caso ainda não estejam criadas por outra rotina de monitoramento

CREATE TABLE [monitoramento].[Historico_Utilizacao_Indices](
[Id_Historico_Utilizacao_Indices] [int] IDENTITY(1,1) NOT NULL,
[Dt_Historico] DATE NULL,
[Id_Servidor] [smallint] NULL,
[Id_BaseDados] [smallint] NULL,
[Id_Tabela] [int] NULL,
[Nm_Indice] [varchar](1000) NULL,
[User_Seeks] [int] NULL,
[User_Scans] [int] NULL,
[User_Lookups] [int] NULL,
[User_Updates] [int] NULL,
[Ultimo_Acesso] [datetime] NULL
) ON [PRIMARY]

GO

create view [monitoramento].vwHistorico_Utilizacao_Indice
AS
select A.Dt_Historico, B.Nm_Servidor, C.Nm_Database,D.Nm_Tabela ,A.Nm_Indice, 
	A.User_Seeks, A.User_Scans, A.User_Lookups, A.User_Updates,A.Ultimo_Acesso
from Historico_Utilizacao_Indices A
	join [monitoramento].Servidor B on A.Id_Servidor = B.Id_Servidor
	join [monitoramento].BaseDados C on A.Id_BaseDados = C.Id_BaseDados
	join [monitoramento].TabelaBD D on A.Id_Tabela = D.Id_Tabela

GO

CREATE procedure [monitoramento].[stpCarga_Utilizacao_Indice]
AS
BEGIN
	SET NOCOUNT ON
	 	
	IF object_id('tempdb..#Historico_Utilizacao_Indices') IS NOT NULL DROP TABLE #Historico_Utilizacao_Indices
	
	CREATE TABLE #Historico_Utilizacao_Indices(
		[Id_Historico_Utilizacao_Indices] [int] IDENTITY(1,1) NOT NULL,
		[Dt_Historico] date NULL,
		[Nm_Servidor] [varchar](50) NULL,
		[Nm_Database] [varchar](100) NULL,
		[Nm_Tabela] [varchar](1000) NULL,
		[Nm_Indice] [varchar](1000) NULL,
		[User_Seeks] [int] NULL,
		[User_Scans] [int] NULL,
		[User_Lookups] [int] NULL,
		[User_Updates] [int] NULL,
		[Ultimo_Acesso] [datetime] NULL
	) ON [PRIMARY]

	insert into #Historico_Utilizacao_Indices(Dt_Historico, [Nm_Servidor], [Nm_Database], [Nm_Tabela], [Nm_Indice], User_Seeks, User_Scans, User_Lookups, User_Updates, Ultimo_Acesso)
 	select cast(monitoramento.getdate2() as date), @@servername,DB_NAME(), o.Name,i.name, s.user_seeks,s.user_scans,s.user_lookups, s.user_Updates, 
		isnull(s.last_user_seek,isnull(s.last_user_scan,s.last_User_Lookup)) Ultimo_acesso
	from sys.dm_db_index_usage_stats s
		 join sys.indexes i on i.object_id = s.object_id and i.index_id = s.index_id
		 join sys.sysobjects o on i.object_id = o.id
	where s.database_id = db_id()
	order by o.Name, i.name, s.index_id

    INSERT INTO [monitoramento].Servidor(Nm_Servidor)
	SELECT DISTINCT A.Nm_Servidor 
	FROM #Historico_Utilizacao_Indices A
		LEFT JOIN [monitoramento].Servidor B ON A.Nm_Servidor = B.Nm_Servidor
	WHERE B.Nm_Servidor IS null
		
	INSERT INTO [monitoramento].BaseDados(Nm_Database)
	SELECT DISTINCT A.Nm_Database 
	FROM #Historico_Utilizacao_Indices A
		LEFT JOIN [monitoramento].BaseDados B ON A.Nm_Database = B.Nm_Database
	WHERE B.Nm_Database IS null
	
	INSERT INTO [monitoramento].TabelaBD(Nm_Tabela)
	SELECT DISTINCT A.Nm_Tabela 
	FROM #Historico_Utilizacao_Indices A
		LEFT JOIN [monitoramento].TabelaBD B ON A.Nm_Tabela = B.Nm_Tabela
	WHERE B.Nm_Tabela IS null	

    INSERT INTO [monitoramento].Historico_Utilizacao_Indices(Dt_Historico, Id_Servidor, Id_BaseDados, Id_Tabela, Nm_Indice, User_Seeks, 
							User_Scans, User_Lookups, User_Updates, Ultimo_Acesso)	
    SELECT A.Dt_Historico, E.Id_Servidor, D.Id_BaseDados,C.Id_Tabela,A.Nm_Indice,A.User_Seeks,A.User_Scans,A.User_Lookups,A.User_Updates,A.Ultimo_Acesso 
    FROM #Historico_Utilizacao_Indices A 
    	JOIN [monitoramento].TabelaBD C ON A.Nm_Tabela = C.Nm_Tabela
		JOIN [monitoramento].BaseDados D ON A.Nm_Database = D.Nm_Database
		JOIN [monitoramento].Servidor E ON A.Nm_Servidor = E.Nm_Servidor 
    	LEFT JOIN [monitoramento].Historico_Utilizacao_Indices B ON E.Id_Servidor = B.Id_Servidor AND D.Id_BaseDados = B.Id_BaseDados  
    													AND C.Id_Tabela = B.Id_Tabela AND A.Nm_Indice = B.Nm_Indice 
    													AND CONVERT(VARCHAR, A.Dt_Historico ,112) = CONVERT(VARCHAR, B.Dt_Historico ,112)
	WHERE A.Nm_Indice IS NOT NULL AND B.Id_Historico_Utilizacao_Indices IS NULL
    ORDER BY 2,3,4,5
	
	delete from [monitoramento].Historico_Utilizacao_Indices
	where Dt_Historico < getdate()-120

        			
end

GO
	
/*
	--Após criado os scripts, rodar a procedure para popular os dados. Essa procedure deve ser agendada no azure uma vez por dia.
	exec [monitoramento].stpCarga_Utilizacao_Indice

	--Conferindo os dados.
	select top 10 *
	from [monitoramento].vwHistorico_Utilizacao_Indice
	order by User_Seeks desc
*/