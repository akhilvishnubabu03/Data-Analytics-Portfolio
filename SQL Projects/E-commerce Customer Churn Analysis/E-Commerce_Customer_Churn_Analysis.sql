USE ecomm;

-- 1. Impute mean for the following columns, and round off to the nearest integer if required: WarehouseToHome, HourSpendOnApp, OrderAmountHikeFromlastYear, DaySinceLastOrder.

SET SQL_SAFE_UPDATES = 0;

SET @avg_wh = (SELECT ROUND(AVG(WarehouseToHome)) FROM customer_churn WHERE WarehouseToHome IS NOT NULL);
SET @avg_hr = (SELECT ROUND(AVG(HourSpendOnApp)) FROM customer_churn WHERE HourSpendOnApp IS NOT NULL);
SET @avg_oh = (SELECT ROUND(AVG(OrderAmountHikeFromlastYear)) FROM customer_churn WHERE OrderAmountHikeFromlastYear IS NOT NULL);
SET @avg_ds = (SELECT ROUND(AVG(DaySinceLastOrder)) FROM customer_churn WHERE DaySinceLastOrder IS NOT NULL);

UPDATE customer_churn
SET
    WarehouseToHome = IFNULL(WarehouseToHome, @avg_wh),
    HourSpendOnApp = IFNULL(HourSpendOnApp, @avg_hr),
    OrderAmountHikeFromlastYear = IFNULL(OrderAmountHikeFromlastYear, @avg_oh),
    DaySinceLastOrder = IFNULL(DaySinceLastOrder, @avg_ds);




-- 2. Impute mode for the following columns: Tenure, CouponUsed, OrderCount.



SET @mode_tenure = (
    SELECT Tenure
    FROM customer_churn
    WHERE Tenure IS NOT NULL
    GROUP BY Tenure
    ORDER BY COUNT(*) DESC
    LIMIT 1
);

SET @mode_coupon = (
    SELECT CouponUsed
    FROM customer_churn
    WHERE CouponUsed IS NOT NULL
    GROUP BY CouponUsed
    ORDER BY COUNT(*) DESC
    LIMIT 1
);

SET @mode_ordercount = (
    SELECT OrderCount
    FROM customer_churn
    WHERE OrderCount IS NOT NULL
    GROUP BY OrderCount
    ORDER BY COUNT(*) DESC
    LIMIT 1
);

UPDATE customer_churn
SET
    Tenure = IFNULL(Tenure, @mode_tenure),
    CouponUsed = IFNULL(CouponUsed, @mode_coupon),
    OrderCount = IFNULL(OrderCount, @mode_ordercount)
WHERE CustomerID IS NOT NULL;


-- 3. Handle outliers in the 'WarehouseToHome' column by deleting rows where the values are greater than 100.

DELETE FROM customer_churn
WHERE WarehouseToHome > 100
  AND CustomerID IS NOT NULL;


-- 4 . Replace occurrences of “Phone” in the 'PreferredLoginDevice' column and “Mobile” in the 'PreferedOrderCat' column with “Mobile Phone” to ensure uniformity.

UPDATE customer_churn
SET
    PreferredLoginDevice = CASE
        WHEN PreferredLoginDevice = 'Phone' THEN 'Mobile Phone'
        ELSE PreferredLoginDevice
    END,
    PreferedOrderCat = CASE
        WHEN PreferedOrderCat = 'Mobile' THEN 'Mobile Phone'
        ELSE PreferedOrderCat
    END
WHERE CustomerID IS NOT NULL;

-- 5. Standardize payment mode values: Replace "COD" with "Cash on Delivery" and "CC" with "Credit Card" in the PreferredPaymentMode column.

UPDATE customer_churn
SET PreferredPaymentMode = CASE
    WHEN PreferredPaymentMode = 'COD' THEN 'Cash on Delivery'
    WHEN PreferredPaymentMode = 'CC'  THEN 'Credit Card'
    ELSE PreferredPaymentMode
END
WHERE CustomerID IS NOT NULL;

-- 6. Rename the column "PreferedOrderCat" to "PreferredOrderCat".

ALTER TABLE customer_churn
CHANGE COLUMN PreferedOrderCat PreferredOrderCat VARCHAR(20);

-- 7. Rename the column "HourSpendOnApp" to "HoursSpentOnApp".

ALTER TABLE customer_churn
CHANGE COLUMN HourSpendOnApp HoursSpentOnApp INT;

-- 8. Create a new column named ‘ComplaintReceived’ with values "Yes" if the corresponding value in the ‘Complain’ is 1, and "No" otherwise.

ALTER TABLE customer_churn
ADD COLUMN ComplaintReceived VARCHAR(3);

UPDATE customer_churn
SET ComplaintReceived = CASE
    WHEN Complain = 1 THEN 'Yes'
    ELSE 'No'
END
WHERE CustomerID IS NOT NULL;

-- 9. Create a new column named 'ChurnStatus'. Set its value to “Churned” if the corresponding value in the 'Churn' column is 1, else assign “Active”.

ALTER TABLE customer_churn
ADD COLUMN ChurnStatus VARCHAR(10);

UPDATE customer_churn
SET ChurnStatus = CASE
    WHEN Churn = 1 THEN 'Churned'
    ELSE 'Active'
END
WHERE CustomerID IS NOT NULL;

-- 10. Drop the columns "Churn" and "Complain" from the table.

ALTER TABLE customer_churn
DROP COLUMN Churn,
DROP COLUMN Complain;

-- 11. Retrieve the count of churned and active customers from the dataset.

SELECT 
    ChurnStatus,
    COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY ChurnStatus;

-- 12. Display the average tenure and total cashback amount of customers who churned.

SELECT
    AVG(Tenure) AS AverageTenure,
    SUM(CashbackAmount) AS TotalCashbackAmount
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- 13. Determine the percentage of churned customers who complained.

SELECT
    (COUNT(CASE WHEN ComplaintReceived = 'Yes' THEN 1 END) * 100.0
     / COUNT(*)) AS Churned_Complaint_Percentage
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- 14. Identify the city tier with the highest number of churned customers whose preferred order category is Laptop & Accessory.

SELECT
    CityTier,
    COUNT(*) AS ChurnedCustomerCount
FROM customer_churn
WHERE ChurnStatus = 'Churned'
  AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY ChurnedCustomerCount DESC
LIMIT 1;

-- 15. Identify the most preferred payment mode among active customers.

SELECT
    PreferredPaymentMode,
    COUNT(*) AS CustomerCount
FROM customer_churn
WHERE ChurnStatus = 'Active'
GROUP BY PreferredPaymentMode
ORDER BY CustomerCount DESC
LIMIT 1;

-- 16. Calculate the total order amount hike from last year for customers who are single and prefer mobile phones for ordering.

SELECT
    SUM(OrderAmountHikeFromlastYear) AS TotalOrderAmountHike
FROM customer_churn
WHERE MaritalStatus = 'Single'
  AND PreferredOrderCat = 'Mobile Phone';

-- 17. Find the average number of devices registered among customers who used UPI as their preferred payment mode.

SELECT
    AVG(NumberOfDeviceRegistered) AS AvgDevicesRegistered
FROM customer_churn
WHERE PreferredPaymentMode = 'UPI';

-- 18. Determine the city tier with the highest number of customers.

SELECT
    CityTier,
    COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY CityTier
ORDER BY CustomerCount DESC
LIMIT 1;

-- 19. Identify the gender that utilized the highest number of coupons.

SELECT
    Gender,
    SUM(CouponUsed) AS TotalCouponsUsed
FROM customer_churn
GROUP BY Gender
ORDER BY TotalCouponsUsed DESC
LIMIT 1;

-- 20. List the number of customers and the maximum hours spent on the app in each preferred order category.

SELECT
    PreferredOrderCat,
    COUNT(*) AS CustomerCount,
    MAX(HoursSpentOnApp) AS MaxHoursSpentOnApp
FROM customer_churn
GROUP BY PreferredOrderCat;

-- 21. Calculate the total order count for customers who prefer using credit cards and have the maximum satisfaction score.

SELECT
    SUM(OrderCount) AS TotalOrderCount
FROM customer_churn
WHERE PreferredPaymentMode = 'Credit Card'
  AND SatisfactionScore = (
      SELECT MAX(SatisfactionScore)
      FROM customer_churn
  );
  
-- 22. What is the average satisfaction score of customers who have complained?

SELECT
    AVG(SatisfactionScore) AS AvgSatisfactionScore
FROM customer_churn
WHERE ComplaintReceived = 'Yes';

-- 23. List the preferred order category among customers who used more than 5 coupons.

SELECT DISTINCT
    PreferredOrderCat
FROM customer_churn
WHERE CouponUsed > 5;

-- 24. List the top 3 preferred order categories with the highest average cashback amount.

SELECT
    PreferredOrderCat,
    AVG(CashbackAmount) AS AvgCashbackAmount
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY AvgCashbackAmount DESC
LIMIT 3;

-- 25. Find the preferred payment modes of customers whose average tenure is 10 months and have placed more than 500 orders.

SELECT
    PreferredPaymentMode
FROM customer_churn
GROUP BY PreferredPaymentMode
HAVING AVG(Tenure) = 10
   AND SUM(OrderCount) > 500;
   
-- 26. Categorize customers based on their distance from the warehouse to home such as 'Very Close Distance' for distances <=5km, 'Close Distance' for <=10km, 'Moderate Distance' for <=15km, and 'Far Distance' for >15km. Then, display the churn status breakdown for each distance category.

SELECT
    DistanceCategory,
    ChurnStatus,
    COUNT(*) AS CustomerCount
FROM (
    SELECT
        CASE
            WHEN WarehouseToHome <= 5  THEN 'Very Close Distance'
            WHEN WarehouseToHome <= 10 THEN 'Close Distance'
            WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
            ELSE 'Far Distance'
        END AS DistanceCategory,
        ChurnStatus
    FROM customer_churn
) t
GROUP BY DistanceCategory, ChurnStatus
ORDER BY DistanceCategory, ChurnStatus;

-- 27. List the customer’s order details who are married, live in City Tier-1, and their
	-- order counts are more than the average number of orders placed by all customers.

SELECT
    CustomerID,
    OrderCount
FROM customer_churn
WHERE MaritalStatus = 'Married'
  AND CityTier = 1
  AND OrderCount > (
      SELECT AVG(OrderCount)
      FROM customer_churn
  );

-- 28. Create customer_returns table and insert data

CREATE TABLE customer_returns (
    ReturnID INT PRIMARY KEY,
    CustomerID INT,
    ReturnDate DATE,
    RefundAmount INT
);

INSERT INTO customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount)
VALUES
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);


-- 29. Display return details along with customer details

SELECT
    cr.ReturnID,
    cr.ReturnDate,
    cr.RefundAmount,
    cc.CustomerID,
    cc.ChurnStatus,
    cc.ComplaintReceived,
    cc.CityTier,
    cc.PreferredPaymentMode,
    cc.PreferredOrderCat
FROM customer_returns cr
JOIN customer_churn cc
    ON cr.CustomerID = cc.CustomerID
WHERE cc.ChurnStatus = 'Churned'
  AND cc.ComplaintReceived = 'Yes';















