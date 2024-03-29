/* STEP 1 - ROTINA MONITORA TAMANHO DAS TABELAS - DONE  */

/*

	Instruções para execução desse Script

	Criar a função abaixo caso ainda não esteja criada
	
	CREATE FUNCTION monitoramento.getdate2()
	RETURNS datetime
	WITH SCHEMABINDING
	AS
		begin
		DECLARE @getdate datetime
		SET @getdate = SYSDATETIMEOFFSET() AT TIME ZONE 'E. South America Standard Time'
		RETURN @getdate
	end


	
*/ 
CREATE  SCHEMA monitoramento


CREATE TABLE [monitoramento].[Historico_Tamanho_Tabela](
	[Id_Historico_Tamanho] [int] IDENTITY(1,1) NOT NULL,
	[Id_Servidor] [smallint] NULL,
	[Id_BaseDados] [smallint] NULL,
	[Id_Tabela] [int] NULL,
	[Nr_Tamanho_Total] [numeric](9, 2) NULL,
	[Nr_Tamanho_Dados] [numeric](9, 2) NULL,
	[Nr_Tamanho_Indice] [numeric](9, 2) NULL,
	[Qt_Linhas] [bigint] NULL,
	[Dt_Referencia] [date] NULL,
 CONSTRAINT [PK_Historico_Tamanho_Tabela] PRIMARY KEY CLUSTERED 
(
	[Id_Historico_Tamanho] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

CREATE  TABLE [monitoramento].[BaseDados](
	[Id_BaseDados] [int] IDENTITY(1,1) NOT NULL,
	[Nm_Database] [varchar](100) NULL
	 CONSTRAINT [PK_BaseDados] PRIMARY KEY CLUSTERED (Id_BaseDados)

) ON [PRIMARY]



CREATE  TABLE [monitoramento].TabelaBD(
	[Id_Tabela] [int] IDENTITY(1,1) NOT NULL,
	[Nm_Tabela] [varchar](1000) NULL,
 CONSTRAINT [PK_TabelaBD] PRIMARY KEY CLUSTERED 
(
	[Id_Tabela] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]


CREATE  TABLE [monitoramento].[Servidor](
	[Id_Servidor] [int] IDENTITY(1,1) NOT NULL,
	[Nm_Servidor] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Servidor] PRIMARY KEY CLUSTERED 
(
	[Id_Servidor] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


create view [monitoramento].vwTamanho_Tabela
AS
select A.Dt_Referencia, B.Nm_Servidor, C.Nm_Database,D.Nm_Tabela , A.Nr_Tamanho_Total, A.Nr_Tamanho_Dados,
	A.Nr_Tamanho_Indice, A.Qt_Linhas
from [monitoramento].Historico_Tamanho_Tabela A
	join [monitoramento].Servidor B on A.Id_Servidor = B.Id_Servidor
	join [monitoramento].BaseDados C on A.Id_BaseDados = C.Id_BaseDados
	join [monitoramento].TabelaBD D on A.Id_Tabela = D.Id_Tabela


GO


CREATE procedure [monitoramento].[stpCarga_Tamanhos_Tabelas]
as

	if object_id('tempdb..#Tamanho_Tabelas') is not null 
		drop table #Tamanho_Tabelas
				
	CREATE TABLE #Tamanho_Tabelas(
		Nm_Servidor VARCHAR(256),
		Nm_Database varchar(256),
		[Nm_Schema] [varchar](8000) NULL,
		[Nm_Tabela] [varchar](8000) NULL,
		[Nm_Index] [varchar](8000) NULL,	
		[Used_in_kb] [int] NULL,
		[Reserved_in_kb] [int] NULL,
		[Tbl_Rows] [bigint] NULL,
		[Type_Desc] [varchar](20) NULL
	) ON [PRIMARY]

	insert into #Tamanho_Tabelas
	select @@SERVERNAME Nm_Servidor						
		, db_name() Nm_Database, t.schema_name, t.table_Name, t.Index_name,
	sum(t.used) as used_in_kb,
	sum(t.reserved) as Reserved_in_kb,
		max(t.tbl_rows)  as rows,
	type_Desc
	from (
		select s.name as schema_name, 
				o.name as table_Name,
				coalesce(i.name,'heap') as Index_name,
				p.used_page_Count*8 as used,
				p.reserved_page_count*8 as reserved, 
				p.row_count as ind_rows,
				(case when i.index_id in (0,1) then p.row_count else 0 end) as tbl_rows, 
				i.type_Desc as type_Desc
		from 
			sys.dm_db_partition_stats p
			join sys.objects o on o.object_id = p.object_id
			join sys.schemas s on s.schema_id = o.schema_id
			left join sys.indexes i on i.object_id = p.object_id and i.index_id = p.index_id
		where o.type_desc = 'user_Table' and o.is_Ms_shipped = 0
	) as t
	group by t.schema_name, t.table_Name,t.Index_name,type_Desc

			
	INSERT INTO [monitoramento].Servidor(Nm_Servidor)
	SELECT DISTINCT A.Nm_Servidor 
	FROM #Tamanho_Tabelas A
		LEFT JOIN [monitoramento].Servidor B ON A.Nm_Servidor = B.Nm_Servidor
	WHERE B.Nm_Servidor IS null
		
	INSERT INTO [monitoramento].BaseDados(Nm_Database)
	SELECT DISTINCT A.Nm_Database 
	FROM #Tamanho_Tabelas A
		LEFT JOIN [monitoramento].BaseDados B ON A.Nm_Database = B.Nm_Database
	WHERE B.Nm_Database IS null
	
	INSERT INTO [monitoramento].TabelaBD(Nm_Tabela)
	SELECT DISTINCT A.Nm_Tabela 
	FROM #Tamanho_Tabelas A
		LEFT JOIN [monitoramento].TabelaBD B ON A.Nm_Tabela = B.Nm_Tabela
	WHERE B.Nm_Tabela IS null	

	insert into [monitoramento].Historico_Tamanho_Tabela(Id_Servidor,Id_BaseDados,Id_Tabela,Nr_Tamanho_Total,
				Nr_Tamanho_Dados,Nr_Tamanho_Indice,Qt_Linhas,Dt_Referencia)
	select B.Id_Servidor, D.Id_BaseDados, C.Id_Tabela ,
			sum(Reserved_in_kb)/1024.00 [Reservado (KB)], 
			sum(case when Type_Desc in ('CLUSTERED','HEAP') then Reserved_in_kb else 0 end)/1024.00 [Dados (KB)], 
			sum(case when Type_Desc in ('NONCLUSTERED') then Reserved_in_kb else 0 end)/1024.00 [Indices (KB)],
			max(Tbl_Rows) Qtd_Linhas,
			CONVERT(VARCHAR, [monitoramento].getdate2() ,112)						 
	from #Tamanho_Tabelas A
		JOIN [monitoramento].Servidor B ON A.Nm_Servidor = B.Nm_Servidor 
		JOIN [monitoramento].TabelaBD C ON A.Nm_Tabela = C.Nm_Tabela
		JOIN [monitoramento].BaseDados D ON A.Nm_Database = D.Nm_Database
			LEFT JOIN [monitoramento].Historico_Tamanho_Tabela E ON B.Id_Servidor = E.Id_Servidor 
								AND D.Id_BaseDados = E.Id_BaseDados AND C.Id_Tabela = E.Id_Tabela 
								AND E.Dt_Referencia = CONVERT(VARCHAR, [monitoramento].getdate2() ,112)    
	where Nm_Index is not null	and Type_Desc is not NULL
		AND E.Id_Historico_Tamanho IS NULL 
	group by B.Id_Servidor, D.Id_BaseDados, C.Id_Tabela, E.Dt_Referencia

	--Mantém 6 meses de dados na tabela de histórico
	delete from Historico_Tamanho_Tabela
	where Dt_Referencia < getdate()-180

GO

/*
	--Após criado os scripts, rodar a procedure para popular os dados. Essa procedure deve ser agendada no azure uma vez por dia.
	exec [monitoramento].stpCarga_Tamanhos_Tabelas
  
  
	--Conferindo os dados.
	select top 10 *
	from [monitoramento].vwTamanho_Tabela
	order by Nr_Tamanho_Total desc
	
*/
