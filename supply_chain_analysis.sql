-- Supply Chain & Inventory Analytics
-- MySQL project: create schema, load tables, and run analytical queries.

CREATE DATABASE IF NOT EXISTS supply_chain_analysis;
USE supply_chain_analysis;

-- Create dimension/fact tables to match the Excel workbook.
CREATE TABLE Products (
    Product_ID VARCHAR(20) PRIMARY KEY,
    Product_Name VARCHAR(100),
    Category VARCHAR(50),
    Unit_Cost DECIMAL(12,2),
    Unit_Price DECIMAL(12,2),
    Supplier_ID VARCHAR(20)
);

CREATE TABLE Suppliers (
    Supplier_ID VARCHAR(20) PRIMARY KEY,
    Supplier_Name VARCHAR(100),
    Supplier_Region VARCHAR(30),
    Lead_Time_Days INT,
    Supplier_Rating DECIMAL(3,1)
);

CREATE TABLE Warehouses (
    Warehouse_ID VARCHAR(20) PRIMARY KEY,
    Warehouse VARCHAR(100),
    Region VARCHAR(30),
    Capacity_Units INT
);

CREATE TABLE Customers (
    Customer_ID VARCHAR(20) PRIMARY KEY,
    Customer_Segment VARCHAR(50),
    Customer_Region VARCHAR(30)
);

CREATE TABLE Orders (
    Order_ID VARCHAR(20) PRIMARY KEY,
    Order_Date DATE,
    Customer_ID VARCHAR(20),
    Product_ID VARCHAR(20),
    Warehouse_ID VARCHAR(20),
    Quantity INT,
    Discount_Pct DECIMAL(5,2),
    Shipping_Cost DECIMAL(12,2),
    Delivery_Days INT,
    Return_Flag VARCHAR(10),
    Order_Status VARCHAR(30),
    Unit_Cost DECIMAL(12,2),
    Unit_Price DECIMAL(12,2),
    Gross_Sales DECIMAL(14,2),
    Discount_Amount DECIMAL(14,2),
    Net_Sales DECIMAL(14,2),
    Product_Cost DECIMAL(14,2),
    Profit DECIMAL(14,2),
    On_Time_Delivery VARCHAR(10)
);

CREATE TABLE Inventory (
    Snapshot_Date DATE,
    Product_ID VARCHAR(20),
    Warehouse_ID VARCHAR(20),
    Stock_On_Hand INT,
    Reorder_Level INT,
    Units_Sold_30D INT,
    Stock_Status VARCHAR(30),
    Days_of_Cover DECIMAL(12,1)
);

-- 1. Overall business KPIs
SELECT
    COUNT(DISTINCT Order_ID) AS total_orders,
    ROUND(SUM(Net_Sales),2) AS net_sales,
    ROUND(SUM(Profit),2) AS total_profit,
    ROUND(SUM(Profit)/NULLIF(SUM(Net_Sales),0)*100,2) AS profit_margin_pct,
    ROUND(AVG(Delivery_Days),2) AS avg_delivery_days,
    ROUND(SUM(Return_Flag='Yes')/COUNT(*)*100,2) AS return_rate_pct,
    ROUND(SUM(On_Time_Delivery='Yes')/COUNT(*)*100,2) AS on_time_delivery_pct
FROM Orders;

-- 2. Monthly sales and profit trend
SELECT
    DATE_FORMAT(Order_Date,'%Y-%m') AS month,
    ROUND(SUM(Net_Sales),2) AS net_sales,
    ROUND(SUM(Profit),2) AS profit,
    COUNT(DISTINCT Order_ID) AS orders
FROM Orders
WHERE Order_Status <> 'Cancelled'
GROUP BY DATE_FORMAT(Order_Date,'%Y-%m')
ORDER BY month;

-- 3. Category performance
SELECT
    p.Category,
    ROUND(SUM(o.Net_Sales),2) AS net_sales,
    ROUND(SUM(o.Profit),2) AS profit,
    ROUND(SUM(o.Profit)/NULLIF(SUM(o.Net_Sales),0)*100,2) AS margin_pct,
    SUM(o.Quantity) AS units_sold
FROM Orders o
JOIN Products p ON o.Product_ID = p.Product_ID
GROUP BY p.Category
ORDER BY net_sales DESC;

-- 4. Warehouse performance
SELECT
    w.Warehouse,
    w.Region,
    COUNT(DISTINCT o.Order_ID) AS orders,
    ROUND(SUM(o.Net_Sales),2) AS net_sales,
    ROUND(SUM(o.Profit),2) AS profit,
    ROUND(AVG(o.Delivery_Days),2) AS avg_delivery_days
FROM Orders o
JOIN Warehouses w ON o.Warehouse_ID = w.Warehouse_ID
GROUP BY w.Warehouse, w.Region
ORDER BY net_sales DESC;

-- 5. Supplier performance
SELECT
    s.Supplier_Name,
    s.Supplier_Region,
    s.Lead_Time_Days,
    s.Supplier_Rating,
    COUNT(DISTINCT p.Product_ID) AS products_supplied
FROM Suppliers s
LEFT JOIN Products p ON s.Supplier_ID = p.Supplier_ID
GROUP BY s.Supplier_ID, s.Supplier_Name, s.Supplier_Region, s.Lead_Time_Days, s.Supplier_Rating
ORDER BY s.Supplier_Rating DESC;

-- 6. Return analysis
SELECT
    p.Category,
    COUNT(*) AS total_orders,
    SUM(o.Return_Flag='Yes') AS returned_orders,
    ROUND(SUM(o.Return_Flag='Yes')/COUNT(*)*100,2) AS return_rate_pct
FROM Orders o
JOIN Products p ON o.Product_ID = p.Product_ID
GROUP BY p.Category
ORDER BY return_rate_pct DESC;

-- 7. Inventory risk
SELECT
    Stock_Status,
    COUNT(*) AS records,
    ROUND(AVG(Days_of_Cover),1) AS avg_days_of_cover
FROM Inventory
GROUP BY Stock_Status
ORDER BY records DESC;

-- 8. Products needing reorder
SELECT
    i.Product_ID,
    p.Product_Name,
    p.Category,
    i.Warehouse_ID,
    i.Stock_On_Hand,
    i.Reorder_Level,
    i.Units_Sold_30D,
    i.Days_of_Cover
FROM Inventory i
JOIN Products p ON i.Product_ID = p.Product_ID
WHERE i.Stock_Status IN ('Stockout','Reorder Needed')
ORDER BY i.Days_of_Cover ASC;

-- 9. Customer segment analysis
SELECT
    c.Customer_Segment,
    COUNT(DISTINCT o.Customer_ID) AS customers,
    ROUND(SUM(o.Net_Sales),2) AS net_sales,
    ROUND(SUM(o.Profit),2) AS profit,
    ROUND(AVG(o.Net_Sales),2) AS avg_order_value
FROM Orders o
JOIN Customers c ON o.Customer_ID = c.Customer_ID
GROUP BY c.Customer_Segment
ORDER BY net_sales DESC;

-- 10. Top 10 products by profit
SELECT
    p.Product_Name,
    p.Category,
    SUM(o.Quantity) AS units_sold,
    ROUND(SUM(o.Net_Sales),2) AS net_sales,
    ROUND(SUM(o.Profit),2) AS profit
FROM Orders o
JOIN Products p ON o.Product_ID = p.Product_ID
GROUP BY p.Product_ID, p.Product_Name, p.Category
ORDER BY profit DESC
LIMIT 10;
