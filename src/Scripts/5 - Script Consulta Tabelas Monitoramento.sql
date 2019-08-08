/*
	--Após criado os scripts, rodar a procedure para popular os dados. Essa procedure deve ser agendada no azure uma vez por dia.
	exec [monitoramento].stpCarga_Utilizacao_Indice

	--Conferindo os dados.
	select top 10 *
	from [monitoramento].vwHistorico_Utilizacao_Indice
	order by User_Seeks desc
*/


/*
	--Após criado os scripts, rodar a procedure para popular os dados. Essa procedure deve ser agendada no azure uma vez por dia.
	exec monitoramento.stpCarga_Fragmentacao_Indice

	--Conferindo os dados.
	select top 10 *
	from monitoramento.vwHistorico_Fragmentacao_Indice
	order by Avg_Fragmentation_In_Percent desc
	
*/

/* Consulta que retorna statisticas das tabelas */

/*
	--Após criado os scripts, rodar a procedure para popular os dados. Essa procedure deve ser agendada no azure uma vez por dia.
	exec [monitoramento].stpCarga_Tamanhos_Tabelas
  
  
	--Conferindo os dados.
	select top 10 *
	from [monitoramento].vwTamanho_Tabela
	order by Nr_Tamanho_Total desc
	
*/

/*
SELECT top 100 s.name AS statistics_name, s.auto_created, s.user_created,
	s.no_recompute, s.is_incremental, s.is_temporary, s.has_filter,
	p.last_updated, DATEDIFF(day, p.last_updated, SYSDATETIME()) AS days_past,
	h.name AS schema_name, o.name AS table_name, c.name AS computer_name,
	p.rows, p.rows_sampled, p.steps, p.modification_counter
FROM sys.stats AS s
JOIN sys.stats_columns AS i
ON s.stats_id = i.stats_id AND s.object_id = i.object_id
JOIN sys.columns AS c 
ON c.object_id = i.object_id AND c.column_id = i.column_id
JOIN sys.objects AS o
ON s.object_id = o.object_id
JOIN sys.schemas AS h
ON o.schema_id = h.schema_id
OUTER APPLY sys.dm_db_stats_properties(s.object_id, s.stats_id) AS p
WHERE OBJECTPROPERTY(o.object_id, N'IsMSShipped') = 0
ORDER BY days_past DESC
*/



