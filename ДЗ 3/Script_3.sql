/*
В этом ДЗ вы научитесь писать подзапросы и CTE.
Для всех заданий, где возможно, сделайте два варианта запросов:
    через вложенный запрос
    через WITH (для производных таблиц)
Напишите запросы:
*/

/*
    Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), и не сделали ни одной продажи 04 июля 2015 года. 
    Вывести ИД сотрудника и его полное имя. Продажи смотреть в таблице Sales.Invoices.
*/
SELECT      p.PersonID
,           p.FullName            
FROM        Application.People  p
LEFT JOIN   (  
                SELECT  i.SalespersonPersonID
                FROM    Sales.Invoices      i  
                WHERE   i.InvoiceDate = '2015-07-04'
            ) s
            ON s.SalespersonPersonID = p.PersonID
WHERE   p.IsSalesperson = 1
AND     s.SalespersonPersonID is null;

WITH s as (
    SELECT  i.SalespersonPersonID
    FROM    Sales.Invoices      i  
    WHERE   i.InvoiceDate = '2015-07-04'
)
SELECT      p.PersonID
,           p.FullName            
FROM        Application.People  p
LEFT JOIN   s                       ON s.SalespersonPersonID = p.PersonID
WHERE   p.IsSalesperson = 1
AND     s.SalespersonPersonID is null;
