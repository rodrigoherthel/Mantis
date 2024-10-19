1. Status dos bugs em aberto
SELECT Evolua_Status.Status "Status", COUNT(*) "Total"
FROM Evolua_Status
INNER JOIN mantis_bug_table
ON mantis_bug_table.status = Evolua_Status.IdStatus 
WHERE Evolua_Status.IdStatus IN (10,20,50) 
AND mantis_bug_table.project_id IN (1,3,4,6,7,8,9,10)
GROUP BY mantis_bug_table.status 
ORDER BY Evolua_Status.IdStatus


2. Bugs abertos por área
SELECT mantis_project_table.name  "Projeto", COUNT(*) "Qtd"
FROM mantis_bug_table 
INNER JOIN mantis_project_table
ON mantis_bug_table.project_id  = mantis_project_table.id  
WHERE mantis_bug_table.status  IN (10,20,50) 
AND mantis_bug_table.project_id IN (1,3,4,6,7,8,9,10)
GROUP BY mantis_bug_table.project_id  

3. Histórico de Status
SELECT "Abertos", COUNT (*) "Total" FROM mantis_bug_table B
 WHERE
    B.project_id IN (1,3,4,6,7,9,10)
    UNION ALL
SELECT S.Status, COUNT(*) FROM mantis_bug_table B
INNER JOIN Evolua_Status S
ON B.status = S.IdStatus 
WHERE 
B.status IN (90,80,60)
AND B.project_id IN (1,3,4,6,7,9,10)
GROUP BY S.Status 

4. Histórico de prioridades 
SELECT  P.Priority, COUNT(*)
FROM  mantis_bug_table B
INNER JOIN  Evolua_Priority P
ON B.priority = P.Id 
WHERE B.project_id IN (1,3,4,6,7,8,9,10)
GROUP BY P.Priority 
order by P.Id desc

5. Bugs abertos/Fechados em 24 horas
 select "Abertos", 
  COUNT(*) "Qtd"
  from mantis_bug_table t
 where t.project_id IN (1,3,4,6,7,9,10)
  and FROM_UNIXTIME(t.date_submitted, '%Y-%m-%d') = cast(now() as date)
union all
    select "Rejeitados", 
  COUNT(*) "Qtd"
  from mantis_bug_table t
  inner join mantis_bug_history_table h
  ON h.bug_id = t.id
 where t.project_id IN (1,3,4,6,7,9,10)
 and FROM_UNIXTIME(h.date_modified, '%Y-%m-%d') = cast(now() as date)
 and h.new_value in (60) -- 80 = Fechado e 60 = Rejeitado
 union all
   select "Fechados", 
  COUNT(*) "Qtd"
  from mantis_bug_table t
  inner join mantis_bug_history_table h
  ON h.bug_id = t.id
 where t.project_id IN (1,3,4,6,7,9,10)
 and FROM_UNIXTIME(h.date_modified, '%Y-%m-%d') = cast(now() as date)
 and h.new_value in (80) -- 80 = Fechado e 60 = Rejeitado

 6. Resolução fora do prazo
 SELECT 
(SUM(CASE 
WHEN (B.priority = 20) AND (TIMESTAMPDIFF(MINUTE,FROM_UNIXTIME(B.date_submitted),FROM_UNIXTIME(H.date_modified))-TIMESTAMPDIFF(DAY,FROM_UNIXTIME(B.date_submitted),FROM_UNIXTIME(H.date_modified))*814 > 4320) THEN 1
WHEN (B.priority = 30) AND (TIMESTAMPDIFF(MINUTE,FROM_UNIXTIME(B.date_submitted),FROM_UNIXTIME(H.date_modified))-TIMESTAMPDIFF(DAY,FROM_UNIXTIME(B.date_submitted),FROM_UNIXTIME(H.date_modified))*814 > 480) THEN 1
WHEN (B.priority = 40) AND (TIMESTAMPDIFF(MINUTE,FROM_UNIXTIME(B.date_submitted),FROM_UNIXTIME(H.date_modified))-TIMESTAMPDIFF(DAY,FROM_UNIXTIME(B.date_submitted),FROM_UNIXTIME(H.date_modified))*814 > 240) THEN 1
END) / count(*)) * 100
FROM  mantis_bug_table B
INNER JOIN  mantis_bug_history_table H
ON B.id = H.bug_id
WHERE H.field_name = "status" AND H.new_value in ("80","60") AND B.project_id IN (1,3,4,6,7,9,10) AND B.priority IN (20,30,40)


7. Detalhamento dos tickets em aberto
SELECT mantis_bug_table.ID "Id",proj.name "Equipe", mantis_bug_table.summary "Descrição", 
FROM_UNIXTIME(mantis_bug_table.date_submitted) "Aberto em",
P.Priority "Prioridade",
CONCAT(
	TIMESTAMPDIFF(HOUR, FROM_UNIXTIME(mantis_bug_table.date_submitted), NOW()),
  	":",
  	MOD(TIMESTAMPDIFF(MINUTE, FROM_UNIXTIME(mantis_bug_table.date_submitted), NOW()),60)
  ) "Tempo",
   SUBSTRING_INDEX(users.email, '@', 1) "Aberto por",
   SUBSTRING_INDEX(mantis_user_table.username, '@', 1)  "Técnico",
UPPER(Evolua_Status.status) Status
FROM mantis_bug_table
INNER JOIN Evolua_Status
ON mantis_bug_table.status = Evolua_Status.IdStatus
INNER JOIN mantis_project_table proj
ON mantis_bug_table.project_id = proj.id 
LEFT JOIN mantis_user_table
ON mantis_bug_table.handler_id = mantis_user_table.Id
inner join mantis_user_table users
ON users.id = mantis_bug_table.reporter_id
INNER JOIN Evolua_Priority P
on mantis_bug_table.priority = P.Id 
WHERE mantis_bug_table.project_id IN (1,3,4,6,7,9,10)
AND Evolua_Status.IdStatus IN (10,20, 50) 
ORDER BY mantis_bug_table.date_submitted


8. Bugs abertos/Fechados em 7 dias
SELECT FROM_UNIXTIME(mantis_bug_history_table.date_modified,'%d/%m') DATA, ABERTOS, count(*) RESOLVIDOS
FROM mantis_bug_table 
INNER JOIN Evolua_Status 
ON mantis_bug_table.status = Evolua_Status.IdStatus
INNER JOIN mantis_bug_history_table
ON mantis_bug_history_table.bug_id = mantis_bug_table.id
CROSS JOIN 
	(
		SELECT FROM_UNIXTIME(mantis_bug_table.date_submitted,'%d/%m') DATA, count(*) ABERTOS
		FROM mantis_bug_table
		WHERE mantis_bug_table.project_id IN (1,3,4,6,7,9,10)
		GROUP BY DATE(FROM_UNIXTIME(mantis_bug_table.date_submitted))
		ORDER BY DATA DESC
	) TbAbertos
ON TbAbertos.DATA = FROM_UNIXTIME(mantis_bug_history_table.date_modified,'%d/%m')
WHERE mantis_bug_table.project_id IN (1,3,4,6,7,9,10)
AND mantis_bug_history_table.field_name = "status"
AND mantis_bug_history_table.new_value = 80
AND mantis_bug_table.date_submitted > UNIX_TIMESTAMP(CURRENT_DATE - INTERVAL 7 DAY)
GROUP BY DATE(FROM_UNIXTIME(mantis_bug_history_table.date_modified))
ORDER BY FROM_UNIXTIME(mantis_bug_history_table.date_modified) ASC


9. Bugs abertos/Fechados em 30 dias
SELECT FROM_UNIXTIME(mantis_bug_history_table.date_modified,'%d/%m') DATA, ABERTOS, count(*) RESOLVIDOS
FROM mantis_bug_table 
INNER JOIN Evolua_Status 
ON mantis_bug_table.status = Evolua_Status.IdStatus
INNER JOIN mantis_bug_history_table
ON mantis_bug_history_table.bug_id = mantis_bug_table.id
CROSS JOIN 
	(
		SELECT FROM_UNIXTIME(mantis_bug_table.date_submitted,'%d/%m') DATA, count(*) ABERTOS
		FROM mantis_bug_table
		WHERE mantis_bug_table.project_id IN (1,3,4,6,7,9,10)
		GROUP BY DATE(FROM_UNIXTIME(mantis_bug_table.date_submitted))
		ORDER BY DATA DESC
	) TbAbertos
ON TbAbertos.DATA = FROM_UNIXTIME(mantis_bug_history_table.date_modified,'%d/%m')
WHERE mantis_bug_table.project_id IN (1,3,4,6,7,9,10)
AND mantis_bug_history_table.field_name = "status"
AND mantis_bug_history_table.new_value = 80
AND mantis_bug_table.date_submitted > UNIX_TIMESTAMP(CURRENT_DATE - INTERVAL 30 DAY)
GROUP BY DATE(FROM_UNIXTIME(mantis_bug_history_table.date_modified))
ORDER BY FROM_UNIXTIME(mantis_bug_history_table.date_modified) ASC


10. Abertos/Fechado por Ano
SELECT
  YEAR(
    FROM_UNIXTIME(mantis_bug_history_table.date_modified)
  ) ANO,
  ABERTOS,
  count(*) RESOLVIDOS
FROM
  mantis_bug_table
  INNER JOIN Evolua_Status ON mantis_bug_table.status = Evolua_Status.IdStatus
  INNER JOIN mantis_bug_history_table ON mantis_bug_history_table.bug_id = mantis_bug_table.id
  CROSS JOIN (
    SELECT
      YEAR(FROM_UNIXTIME(mantis_bug_table.date_submitted)) DATA,
      count(*) ABERTOS
    FROM
      mantis_bug_table
    WHERE
      mantis_bug_table.project_id IN (1,3,4,6,7,9,10)
    GROUP BY
      YEAR(FROM_UNIXTIME(mantis_bug_table.date_submitted))
    ORDER BY
      DATA DESC
  ) TbAbertos ON TbAbertos.DATA = YEAR(
    FROM_UNIXTIME(mantis_bug_history_table.date_modified)
  )
WHERE
  mantis_bug_table.project_id IN (1,3,4,6,7,9,10)
  AND mantis_bug_history_table.field_name = "status"
  AND mantis_bug_history_table.new_value IN (80, 60) -- 80 = Fechado e 60 = Rejeitado
GROUP BY
  YEAR(
    FROM_UNIXTIME(mantis_bug_history_table.date_modified)
  )
ORDER BY
  FROM_UNIXTIME(mantis_bug_history_table.date_modified) ASC

  11. Abertos/fechados últimos 12 meses (por mês)
  SELECT MonthName(FROM_UNIXTIME(mantis_bug_history_table.date_modified)) MÊS, ABERTOS, count(*) RESOLVIDOS
FROM mantis_bug_table 
INNER JOIN Evolua_Status 
ON mantis_bug_table.status = Evolua_Status.IdStatus
INNER JOIN mantis_bug_history_table
ON mantis_bug_history_table.bug_id = mantis_bug_table.id
CROSS JOIN 
	(
		SELECT MonthName(FROM_UNIXTIME(mantis_bug_table.date_submitted)) DATA, count(*) ABERTOS
		FROM mantis_bug_table
	    WHERE mantis_bug_table.project_id IN (1,3,4,6,7,9,10)
		GROUP BY MonthName(FROM_UNIXTIME(mantis_bug_table.date_submitted))
		ORDER BY DATA DESC
	) TbAbertos
ON TbAbertos.DATA = MonthName(FROM_UNIXTIME(mantis_bug_history_table.date_modified))
WHERE mantis_bug_table.project_id IN (1,3,4,6,7,9,10)
AND mantis_bug_history_table.field_name = "status"
AND mantis_bug_history_table.new_value in (80, 60) -- 80 = Fechado e 60 = Rejeitado
GROUP BY MonthName(FROM_UNIXTIME(mantis_bug_history_table.date_modified))
ORDER BY FROM_UNIXTIME(mantis_bug_history_table.date_modified) ASC



12. Abertos/fechados últimos 12 meses (por dia)
SELECT FROM_UNIXTIME(mantis_bug_history_table.date_modified,'%d/%m') DATA, ABERTOS, count(*) RESOLVIDOS
FROM mantis_bug_table 
INNER JOIN Evolua_Status 
ON mantis_bug_table.status = Evolua_Status.IdStatus
INNER JOIN mantis_bug_history_table
ON mantis_bug_history_table.bug_id = mantis_bug_table.id
CROSS JOIN 
	(
		SELECT FROM_UNIXTIME(mantis_bug_table.date_submitted,'%d/%m') DATA, count(*) ABERTOS
		FROM mantis_bug_table
		WHERE mantis_bug_table.project_id IN (1,3,4,6,7,9,10)
		GROUP BY DATE(FROM_UNIXTIME(mantis_bug_table.date_submitted))
		ORDER BY DATA DESC
	) TbAbertos
ON TbAbertos.DATA = FROM_UNIXTIME(mantis_bug_history_table.date_modified,'%d/%m')
WHERE mantis_bug_table.project_id IN (1,3,4,6,7,9,10)
AND mantis_bug_history_table.field_name = "status"
AND mantis_bug_history_table.new_value = 80
AND mantis_bug_table.date_submitted > UNIX_TIMESTAMP(CURRENT_DATE - INTERVAL 365 DAY)
GROUP BY DATE(FROM_UNIXTIME(mantis_bug_history_table.date_modified))
ORDER BY FROM_UNIXTIME(mantis_bug_history_table.date_modified) ASC


13. Fracasso de SLA (Alta prioridade)
SELECT 
(SUM(CASE 
WHEN (B.priority = 40) AND
((TIMESTAMPDIFF(MINUTE,FROM_UNIXTIME(B.date_submitted),FROM_UNIXTIME(H.date_modified)) - ((TIMESTAMPDIFF(DAY,FROM_UNIXTIME(B.date_submitted),FROM_UNIXTIME(H.date_modified)))*814)) > 240) THEN 1
END) / count(*)) * 100
FROM  mantis_bug_table B
INNER JOIN  mantis_bug_history_table H
ON B.id = H.bug_id
WHERE H.field_name = "status" AND H.new_value in ("80","60") AND B.project_id IN (1,3,6,7,8,9,10) AND B.priority  IN (40)


14. Fracasso de SLA (Prioridade Normal)
SELECT 
(SUM(CASE 
WHEN (B.priority = 30) AND
((TIMESTAMPDIFF(MINUTE,FROM_UNIXTIME(B.date_submitted),FROM_UNIXTIME(H.date_modified)) - ((TIMESTAMPDIFF(DAY,FROM_UNIXTIME(B.date_submitted),FROM_UNIXTIME(H.date_modified)))*814)) > 480) THEN 1
END) / count(*)) * 100
FROM  mantis_bug_table B
INNER JOIN  mantis_bug_history_table H
ON B.id = H.bug_id
WHERE H.field_name = "status" AND H.new_value in ("80","60") AND B.project_id IN (1,3,4,6,7,9,10) AND B.priority  IN (30)


15. Fracasso de SLA (Baixa Prioridade)
SELECT 
(SUM(CASE 
WHEN (B.priority = 20) AND
((TIMESTAMPDIFF(MINUTE,FROM_UNIXTIME(B.date_submitted),FROM_UNIXTIME(H.date_modified)) - ((TIMESTAMPDIFF(DAY,FROM_UNIXTIME(B.date_submitted),FROM_UNIXTIME(H.date_modified)))*814)) > 4320) THEN 1
END) / count(*)) * 100
FROM  mantis_bug_table B
INNER JOIN  mantis_bug_history_table H
ON B.id = H.bug_id
WHERE H.field_name = "status" AND H.new_value in ("80","60") AND B.project_id IN (1,3,4,6,7,9,10) AND B.priority  IN (20)




