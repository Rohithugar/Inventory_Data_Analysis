CREATE DATABASE Retail_store_inventory;
USE Retail_store_inventory;

CREATE TABLE inventory_data (
    Date DATE,                       
    Store_ID VARCHAR(10),             
    Product_ID VARCHAR(10),           
    Category VARCHAR(50),             
    Region VARCHAR(50),               
    Inventory_Level INT,              
    Units_Sold INT,                   
    Units_Ordered INT,                
    Demand_Forecast INT,              
    Price DECIMAL(10,2),              
    Discount DECIMAL(5,2),            
    Weather_Condition VARCHAR(50),    
    Holiday_Promotion INT,            
    Competitor_Pricing DECIMAL(10,2), 
    Seasonality VARCHAR(20)           
);

LOAD DATA INFILE 'E:/retail_store_inventory_.csv'
INTO TABLE inventory_data
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- Data Overview

SELECT * FROM inventory_data;

SELECT COUNT(*) AS column_count
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'Retail_store_inventory' 
  AND TABLE_NAME = 'inventory_data';
  
SELECT COUNT(*) AS row_count
FROM inventory_data;

SELECT COUNT(*) AS Total_Records, 
       COUNT(DISTINCT Product_ID) AS Unique_Products, 
       COUNT(DISTINCT Store_ID) AS Unique_Stores
FROM inventory_data;

-- Category-Wise Inventory Summary
SELECT Category, 
       SUM(Inventory_Level) AS Total_Inventory, 
       AVG(Units_Sold) AS Avg_Sales, 
       AVG(Price) AS Avg_Price
FROM inventory_data
GROUP BY Category
ORDER BY Total_Inventory DESC;

-- Category-Wise Inventory to sale ratio
SELECT 
    Category, 
    SUM(Inventory_Level) AS Total_Inventory,
    SUM(Units_Sold) AS Total_Sales,
    CASE 
        WHEN SUM(Units_Sold) = 0 THEN NULL -- Avoid division by zero
        ELSE ROUND(SUM(Inventory_Level) * 1.0 / SUM(Units_Sold), 2)
    END AS Inventory_to_Sales_Ratio
FROM inventory_data
GROUP BY Category
ORDER BY Inventory_to_Sales_Ratio DESC; 


-- Regional Inventory Insights
SELECT Region, 
       COUNT(Product_ID) AS Total_Products, 
       SUM(Inventory_Level) AS Total_Inventory
FROM inventory_data
GROUP BY Region
ORDER BY Total_Inventory DESC;

-- Daily Sales Trends
SELECT Date, 
       SUM(Units_Sold) AS Total_Sales
FROM inventory_data
GROUP BY Date
ORDER BY Date;

----------
-- Monthly sales trends
WITH MonthlySales AS (
    SELECT 
        YEAR(Date) AS Year,
        MONTH(date) AS Month,
        SUM(Units_sold) AS TotalSales
    FROM inventory_data
    GROUP BY YEAR(date), MONTH(date)
),
SalesWithPreviousMonth AS (
    SELECT 
        Year,
        Month,
        TotalSales,
        LAG(TotalSales) OVER (ORDER BY Year, Month) AS PreviousMonthSales
    FROM MonthlySales
)
SELECT 
    Year,
    Month,
    TotalSales,
    PreviousMonthSales,
    CASE 
        WHEN PreviousMonthSales = 0 THEN NULL  -- Prevent division by zero
        ELSE ((TotalSales - PreviousMonthSales) / PreviousMonthSales) * 100 
    END AS PercentageIncrease
FROM SalesWithPreviousMonth
ORDER BY Year, Month;


---------
-- Identify Fast-Moving Products
SELECT Product_ID, 
       Category, 
       SUM(Units_Sold) AS Total_Sales
FROM inventory_data
GROUP BY Product_ID, Category
ORDER BY Total_Sales DESC
LIMIT 10;

-- Identify Slow-Moving Products
SELECT Product_ID, 
       Category, 
       SUM(Units_Sold) AS Total_Sales
FROM inventory_data
GROUP BY Product_ID, Category
ORDER BY Total_Sales ASC
LIMIT 10;

-- Overstock Analysis
SELECT Product_ID, 
       Inventory_Level, 
       Demand_Forecast, 
       Inventory_Level - Demand_Forecast AS Overstock_Quantity
FROM inventory_data
WHERE Inventory_Level > Demand_Forecast
ORDER BY Overstock_Quantity DESC;

-- Stockout Risk Analysis
SELECT Product_ID, Category, 
       Inventory_Level, 
       Demand_Forecast, 
       Demand_Forecast - Inventory_Level AS Stockout_Risk
FROM inventory_data
WHERE Inventory_Level < Demand_Forecast
ORDER BY Stockout_Risk DESC;

-- Inventory Turnover Ratio
SELECT Product_ID, 
       Category, 
       SUM(Units_Sold) / NULLIF(SUM(Inventory_Level), 0) AS Turnover_Ratio
FROM inventory_data
GROUP BY Product_ID, Category
ORDER BY Turnover_Ratio DESC;

-- Stock Duration
SELECT Product_ID, 
       ROUND(Inventory_Level / NULLIF(AVG(Units_Sold), 0), 0) AS Stock_Duration
FROM inventory_data
GROUP BY Product_ID, Inventory_Level;

-- Reorder Point Analysis
SELECT Product_ID, 
       ROUND(AVG(Units_Sold) * 5 + 1.65 * STDDEV(Units_Sold), 0) AS Reorder_Point
FROM inventory_data
GROUP BY Product_ID;

-- Seasonal Trends
SELECT Seasonality, 
       SUM(Units_Sold) AS Total_Sales
FROM inventory_data
GROUP BY Seasonality
ORDER BY Total_sales DESC;

-- Holiday/Promotion Impact
SELECT Holiday_Promotion, 
       AVG(Units_Sold) AS Avg_Sales, 
       AVG(Discount) AS Avg_Discount
FROM inventory_data
GROUP BY Holiday_Promotion;

-- Weather Condition Analysis
SELECT Weather_Condition, 
       AVG(Units_Sold) AS Avg_Sales
FROM inventory_data
GROUP BY Weather_Condition;

-- Competitor Price Analysis
SELECT Product_ID, 
       AVG(Competitor_Pricing) AS Avg_Competitor_Price, 
       AVG(Price) AS Avg_Our_Price
FROM inventory_data
GROUP BY Product_ID
ORDER BY Avg_Competitor_Price DESC;

-- Discount Effectiveness
SELECT Discount, 
       AVG(Units_Sold) AS Avg_Sales
FROM inventory_data
GROUP BY Discount
ORDER BY Discount DESC;

-- Top 3 products per region
WITH RankedProducts AS (
    SELECT Region, 
           Product_ID, 
           SUM(Units_Sold) AS Total_Sales,
           ROW_NUMBER() OVER (PARTITION BY Region ORDER BY SUM(Units_Sold) DESC) AS Rk
    FROM inventory_data
    GROUP BY Region, Product_ID
)
SELECT Region, Product_ID, Total_Sales
FROM RankedProducts
WHERE Rk <= 3
ORDER BY Region, Rk;

-- Category-Wise Stock Duration
SELECT Category, 
       ROUND(AVG(Inventory_Level) / NULLIF(AVG(Units_Sold), 0), 0) AS Avg_Stock_Duration
FROM inventory_data
GROUP BY Category
ORDER BY Avg_Stock_Duration DESC;

-- Out-of-Stock Days
SELECT Product_ID, 
       COUNT(*) AS Out_Of_Stock_Days
FROM inventory_data
WHERE Inventory_Level = 0
GROUP BY Product_ID;

-- Total Revenue by Product
SELECT Product_ID, 
       SUM(Units_Sold * Price * (1 - Discount / 100)) AS Total_Revenue
FROM inventory_data
GROUP BY Product_ID
ORDER BY Total_Revenue DESC;

-- Total Revenue by Category
SELECT 
    Category,
    SUM(Units_Sold * Price) AS TotalRevenue
FROM 
    inventory_data
GROUP BY 
    Category
ORDER BY 
    TotalRevenue DESC;
    
    
    





















