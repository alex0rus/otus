/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select  StockItemID, StockItemName
from    Warehouse.StockItems
where   1=1     
and     StockItemName like 'Animal%'
union 
select  StockItemID, StockItemName
from    Warehouse.StockItems
where   1=1     
and     StockItemName like '%urgent%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select      s.SupplierID, s.SupplierName
from        Purchasing.Suppliers s
left join   Purchasing.PurchaseOrders   po  on  po.SupplierID = s.SupplierID
where       po.SupplierID is null  

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

;WITH lo as (
    SELECT      OrderID     = lo.OrderID
    FROM        Sales.OrderLines    lo  
    WHERE       1=1
    AND         lo.UnitPrice > 100
    UNION 
    SELECT      OrderID     = lo.OrderID
    FROM        Sales.OrderLines    lo  
    WHERE       1=1
    AND         lo.Quantity > 20
)
SELECT      OrderID     = o.OrderID
,           OrderDate   = CONVERT(char(10), o.OrderDate, 104)
,           Month       = DATENAME(month, o.OrderDate)  
,           Quarter     = DATEPART(quarter, o.OrderDate)  
,           Quarter2    = MONTH(o.OrderDate)/3 + SIGN(MONTH(o.OrderDate)%3)
,           OneThird    = MONTH(o.OrderDate)/4 + SIGN(MONTH(o.OrderDate)%4)
,           Customer    = c.CustomerName
FROM        Sales.Orders        o
JOIN        lo                      ON  lo.OrderID      = o.OrderID
JOIN        Sales.Customers     c   ON  c.CustomerID    = o.CustomerID
WHERE       1=1
AND         o.PickingCompletedWhen IS NOT NULL
ORDER BY Quarter2, OneThird, o.OrderDate
--OFFSET 1000 ROW FETCH NEXT 100 ROWS ONLY

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT   
        dm.DeliveryMethodName
,       po.ExpectedDeliveryDate        
,       s.SupplierName
,       p.FullName
FROM    Purchasing.Suppliers        s
JOIN    Purchasing.PurchaseOrders   po  ON  po.SupplierID       = s.SupplierID
JOIN    Application.DeliveryMethods dm  ON  dm.DeliveryMethodID = po.DeliveryMethodID
JOIN    Application.People          p   ON  p.PersonID          = s.PrimaryContactPersonID
WHERE   1=1
AND     po.ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31'
AND     dm.DeliveryMethodName IN ('Air Freight', 'Refrigerated Air Freight')

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT  TOP 10
        OrderDate
,       s.FullName  AS SalesPerson
,       p.FullName  AS ContactPerson
FROM    Sales.Orders        o
JOIN    Application.People  s   ON  s.PersonID  = o.SalespersonPersonID
JOIN    Application.People  p   ON  p.PersonID  = o.ContactPersonID
ORDER BY o.OrderDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT  DISTINCT p.FullName, p.PhoneNumber
FROM    Sales.Orders            o
JOIN    Sales.OrderLines        l   ON  l.OrderID       = o.OrderID
JOIN    Warehouse.StockItems    s   ON  s.StockItemID   = l.StockItemID
JOIN    Application.People      p   ON  p.PersonID      = o.ContactPersonID
WHERE   s.StockItemName = 'Chocolate frogs 250g'

/*
7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT  
        [Year]  = YEAR(i.InvoiceDate)
,       [Month] = MONTH(i.InvoiceDate)
,       [AVG]   = AVG(Quantity * UnitPrice)
,       [SUM]   = SUM(Quantity * UnitPrice)
FROM    Sales.Invoices      i
JOIN    Sales.Orders        o   ON  o.OrderID   = i.OrderID
JOIN    Sales.OrderLines    l   ON  l.OrderID   = i.OrderID
WHERE   1=1
AND     i.InvoiceDate BETWEEN '2015-01-01' AND '2015-12-31'
GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)
ORDER BY 2

/*
8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT  
        [Year]  = YEAR(i.InvoiceDate)
,       [Month] = MONTH(i.InvoiceDate)
,       [SUM]   = SUM(Quantity * UnitPrice)
FROM    Sales.Invoices      i
JOIN    Sales.Orders        o   ON  o.OrderID   = i.OrderID
JOIN    Sales.OrderLines    l   ON  l.OrderID   = i.OrderID
WHERE   1=1
AND     i.InvoiceDate BETWEEN '2015-01-01' AND '2015-12-31'
GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate)
HAVING SUM(Quantity * UnitPrice) >= 10000
ORDER BY 2

/*
9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT  
        [Year]  = YEAR(i.InvoiceDate)
,       [Month] = MONTH(i.InvoiceDate)
,       [Name]  = s.StockItemName
,       [SUM]   = SUM(Quantity * l.UnitPrice)
,       [First] = MIN(i.InvoiceDate)
,       [COUNT] = SUM(Quantity)
FROM    Sales.Invoices          i
JOIN    Sales.Orders            o   ON  o.OrderID       = i.OrderID
JOIN    Sales.OrderLines        l   ON  l.OrderID       = i.OrderID
JOIN    Warehouse.StockItems    s   ON  s.StockItemID   = l.StockItemID
WHERE   1=1
GROUP BY YEAR(i.InvoiceDate), MONTH(i.InvoiceDate), s.StockItemName
HAVING SUM(Quantity) < 50
ORDER BY 1, 2, 3

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 8-9 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
