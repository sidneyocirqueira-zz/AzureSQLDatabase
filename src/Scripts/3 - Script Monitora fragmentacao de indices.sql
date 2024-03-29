/* STEP 3 - ROTINA DE MONITORAMENTO FRAGMENTAÇÃO DE INDICES - DONE */

----------------------------- HISTORICO FRAGMENTACAO DE INDICE

/*

	Instruções para execução desse Script

	Criar a função abaixo caso ainda não esteja criada
	
	CREATE FUNCTION dbo.getdate2()
	RETURNS datetime
	WITH SCHEMABINDING
	AS
		begin
		DECLARE @getdate datetime
		SET @getdate = SYSDATETIMEOFFSET() AT TIME ZONE 'E. South America Standard Time'
		RETURN @getdate
	end


	
*/

-- Criar as tabelas abaixo caso ainda não estejam criadas por outra rotina de monitoramento
/*
CREATE TABLE [dbo].[BaseDados](
	[Id_BaseDados] [int] IDENTITY(1,1) NOT NULL,
	[Nm_Database] [varchar](100) NULL
	 CONSTRAINT [PK_BaseDados] PRIMARY KEY CLUSTERED (Id_BaseDados)

) ON [PRIMARY]


CREATE TABLE [dbo].TabelaBD(
	[Id_Tabela] [int] IDENTITY(1,1) NOT NULL,
	[Nm_Tabela] [varchar](1000) NULL,
 CONSTRAINT [PK_TabelaBD] PRIMARY KEY CLUSTERED 
(
	[Id_Tabela] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]


CREATE TABLE [dbo].[Servidor](
	[Id_Servidor] [int] IDENTITY(1,1) NOT NULL,
	[Nm_Servidor] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Servidor] PRIMARY KEY CLUSTERED 
(
	[Id_Servidor] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
*/
CREATE TABLE monitoramento.Historico_Fragmentacao_Indice(
	[Id_Hitorico_Fragmentacao_Indice] [int] IDENTITY(1,1) NOT NULL,
	[Dt_Referencia] date NULL,
	[Id_Servidor] [smallint] NULL,
	[Id_BaseDados] [smallint] NULL,
	[Id_Tabela] [int] NULL,
	[Nm_Indice] [varchar](1000) NULL,
	Nm_Schema varchar(50),
	[Avg_Fragmentation_In_Percent] [numeric](5, 2) NULL,
	[Page_Count] [int] NULL,
	[Fill_Factor] [tinyint] NULL,
	[Fl_Compressao] [tinyint] NULL
) ON [PRIMARY]


GO

create view monitoramento.vwHistorico_Fragmentacao_Indice
AS
select A.Dt_Referencia, B.Nm_Servidor, C.Nm_Database,D.Nm_Tabela ,A.Nm_Indice, A.Nm_Schema, 
	A.Avg_Fragmentation_In_Percent, A.Page_Count, A.Fill_Factor, A.Fl_Compressao
from Historico_Fragmentacao_Indice A
	join monitoramento.Servidor B on A.Id_Servidor = B.Id_Servidor
	join monitoramento.BaseDados C on A.Id_BaseDados = C.Id_BaseDados
	join monitoramento.TabelaBD D on A.Id_Tabela = D.Id_Tabela
GO



CREATE procedure [monitoramento].[stpCarga_Fragmentacao_Indice]
AS
BEGIN
	SET NOCOUNT ON
	 
	
	IF object_id('tempdb..#Historico_Fragmentacao_Indice') IS NOT NULL DROP TABLE #Historico_Fragmentacao_Indice
	
	CREATE TABLE #Historico_Fragmentacao_Indice(
		[Id_Hitorico_Fragmentacao_Indice] [int] IDENTITY(1,1) NOT NULL,
		[Dt_Referencia] date NULL,
		[Nm_Servidor] VARCHAR(50) NULL,
		[Nm_Database] VARCHAR(100) NULL,
		[Nm_Tabela] VARCHAR(1000) NULL,
		[Nm_Indice] [varchar](1000) NULL,
		Nm_Schema varchar(50),
		[Avg_Fragmentation_In_Percent] [numeric](5, 2) NULL,
		[Page_Count] [int] NULL,
		[Fill_Factor] [tinyint] NULL,
		[Fl_Compressao] [tinyint] NULL
	) ON [PRIMARY]

 
	insert into #Historico_Fragmentacao_Indice
	select monitoramento.getdate2(), @@servername Nm_Servidor,  DB_NAME() Nm_Database, D.Name Nm_Tabela,  B.Name Nm_Indice,F.name Nm_Schema, avg_fragmentation_in_percent,
			page_Count,fill_factor,data_compression	
	from sys.dm_db_index_physical_stats(db_id(),null,null,null,null) A
			join sys.indexes B on A.object_id = B.Object_id and A.index_id = B.index_id
            JOIN sys.partitions C ON C.object_id = B.object_id AND C.index_id = B.index_id
            JOIN sys.sysobjects D ON A.object_id = D.id
            join sys.objects E on D.id = E.object_id
            join  sys.schemas F on E.schema_id = F.schema_id
	where page_Count > 1000
            

    INSERT INTO monitoramento.Servidor(Nm_Servidor)
	SELECT DISTINCT A.Nm_Servidor 
	FROM #Historico_Fragmentacao_Indice A
		LEFT JOIN monitoramento.Servidor B ON A.Nm_Servidor = B.Nm_Servidor
	WHERE B.Nm_Servidor IS null
		
	INSERT INTO monitoramento.BaseDados(Nm_Database)
	SELECT DISTINCT A.Nm_Database 
	FROM #Historico_Fragmentacao_Indice A
		LEFT JOIN monitoramento.BaseDados B ON A.Nm_Database = B.Nm_Database
	WHERE B.Nm_Database IS null
	
	INSERT INTO monitoramento.TabelaBD(Nm_Tabela)
	SELECT DISTINCT A.Nm_Tabela 
	FROM #Historico_Fragmentacao_Indice A
		LEFT JOIN TabelaBD B ON A.Nm_Tabela = B.Nm_Tabela
	WHERE B.Nm_Tabela IS null	
	
    INSERT INTO monitoramento.Historico_Fragmentacao_Indice(Dt_Referencia,Id_Servidor,Id_BaseDados,Id_Tabela,Nm_Indice,Nm_Schema,Avg_Fragmentation_In_Percent,
			Page_Count,Fill_Factor,Fl_Compressao)	
    SELECT A.Dt_Referencia,E.Id_Servidor, D.Id_BaseDados,C.Id_Tabela,A.Nm_Indice,A.Nm_Schema,A.Avg_Fragmentation_In_Percent,A.Page_Count,A.Fill_Factor,A.Fl_Compressao 
    FROM #Historico_Fragmentacao_Indice A 
    	JOIN monitoramento.TabelaBD C ON A.Nm_Tabela = C.Nm_Tabela
		JOIN monitoramento.BaseDados D ON A.Nm_Database = D.Nm_Database
		JOIN monitoramento.Servidor E ON A.Nm_Servidor = E.Nm_Servidor 
    	LEFT JOIN monitoramento.Historico_Fragmentacao_Indice B ON E.Id_Servidor = B.Id_Servidor AND D.Id_BaseDados = B.Id_BaseDados  
    													AND C.Id_Tabela = B.Id_Tabela AND A.Nm_Indice = B.Nm_Indice 
    													AND CONVERT(VARCHAR, A.Dt_Referencia ,112) = CONVERT(VARCHAR, B.Dt_Referencia ,112)
	WHERE A.Nm_Indice IS NOT NULL AND B.Id_Hitorico_Fragmentacao_Indice IS NULL
    ORDER BY 2,3,4,5

	-- Vai manter 4 meses de dados na tabela
	delete from monitoramento.Historico_Fragmentacao_Indice
	where Dt_Referencia < getdate()-120

        			
end

/*
	--Após criado os scripts, rodar a procedure para popular os dados. Essa procedure deve ser agendada no azure uma vez por dia.
	exec monitoramento.stpCarga_Fragmentacao_Indice

	--Conferindo os dados.
	select top 10 *
	from monitoramento.vwHistorico_Fragmentacao_Indice
	order by Avg_Fragmentation_In_Percent desc
	
*/




