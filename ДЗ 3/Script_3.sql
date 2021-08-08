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

/*
    Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. Вывести: ИД товара, наименование товара, цена.
*/
SELECT      s.StockItemID
,           s.StockItemName
,           s.UnitPrice
FROM        Warehouse.StockItems    s
JOIN        (
            SELECT  Price = MIN(UnitPrice)
            FROM    Warehouse.StockItems
            )                       p       ON  p.Price = s.UnitPrice;

WITH p as (
    SELECT  Price = MIN(UnitPrice)
    FROM    Warehouse.StockItems
)
SELECT      s.StockItemID
,           s.StockItemName
,           s.UnitPrice            
FROM        Warehouse.StockItems    s
JOIN        p                               ON p.Price = s.UnitPrice;

/* 
    Выберите информацию по клиентам, которые перевели компании пять максимальных платежей из Sales.CustomerTransactions. Представьте несколько способов (в том числе с CTE). 
*/

WITH tbl AS (
    SELECT      TOP 5 MaxAmount = TransactionAmount
    FROM        Sales.CustomerTransactions
    ORDER BY TransactionAmount DESC
)
SELECT      DISTINCT c.CustomerName
FROM        tbl 
JOIN        Sales.CustomerTransactions ct   ON  ct.TransactionAmount = tbl.MaxAmount
JOIN        Sales.Customers             c   ON  c.CustomerID         = ct.CustomerID
ORDER BY 1;

SELECT      DISTINCT c.CustomerName
FROM        
            (
            SELECT      TOP 5 MaxAmount = TransactionAmount
            FROM        Sales.CustomerTransactions
            ORDER BY TransactionAmount DESC                
            ) AS tbl
JOIN        Sales.CustomerTransactions ct   ON  ct.TransactionAmount = tbl.MaxAmount
JOIN        Sales.Customers             c   ON  c.CustomerID         = ct.CustomerID
ORDER BY 1;
