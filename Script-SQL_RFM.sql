use `sql test`
create table calculation as (
SELECT 
    ct.CustomerID,
    DATEDIFF('2022-09-01', MAX(CAST(Purchase_Date AS DATE))) AS recency,
    ROUND(CAST(COUNT(DISTINCT(CAST(Purchase_Date AS DATE))) AS FLOAT) /
          CAST(TIMESTAMPDIFF(YEAR, CAST(created_date AS DATE), '2022-09-01') AS FLOAT), 2) AS frequency,
    SUM(gmv) / TIMESTAMPDIFF(YEAR, CAST(created_date AS DATE), '2022-09-01') AS monetary,
    ROW_NUMBER() OVER (ORDER BY DATEDIFF('2022-09-01', MAX(CAST(Purchase_Date AS DATE)))) AS rn_recency,
    ROW_NUMBER() OVER (ORDER BY ROUND(CAST(COUNT(DISTINCT(CAST(Purchase_Date AS DATE))) AS FLOAT) /
                                       CAST(TIMESTAMPDIFF(YEAR, CAST(created_date AS DATE), '2022-09-01') AS FLOAT), 2)) AS rn_frequency,
    ROW_NUMBER() OVER (ORDER BY SUM(gmv)) AS rn_monetary
from `sql test`.customer_transaction ct 
join `sql test`.customer_register cr  on ct.CustomerID = cr.ID
where ct.CustomerID != 0
group by CustomerID , created_date);

create table result as (SELECT 
    *, 
    CASE
        WHEN recency < (SELECT recency FROM calculation WHERE rn_recency = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.25) FROM calculation))
            THEN '1'
        WHEN recency >= (SELECT recency FROM calculation WHERE rn_recency = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.25) FROM calculation))
             AND recency < (SELECT recency FROM calculation WHERE rn_recency = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.5) FROM calculation))
            THEN '2'
        WHEN recency >= (SELECT recency FROM calculation WHERE rn_recency = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.5) FROM calculation))
             AND recency < (SELECT recency FROM calculation WHERE rn_recency = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.75) FROM calculation))
            THEN '3'
        ELSE '4'
    END AS R,
    CASE
        WHEN frequency < (SELECT frequency FROM calculation WHERE rn_frequency = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.25) FROM calculation))
            THEN '1'
        WHEN frequency >= (SELECT frequency FROM calculation WHERE rn_frequency = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.25) FROM calculation))
             AND frequency < (SELECT frequency FROM calculation WHERE rn_frequency = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.5) FROM calculation))
            THEN '2'
        WHEN frequency >= (SELECT frequency FROM calculation WHERE rn_frequency = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.5) FROM calculation))
             AND frequency < (SELECT frequency FROM calculation WHERE rn_frequency = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.75) FROM calculation))
            THEN '3'
        ELSE '4'
    END AS F,
    CASE
        WHEN monetary < (SELECT monetary FROM calculation WHERE rn_monetary = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.25) FROM calculation))
            THEN '1'
        WHEN monetary >= (SELECT monetary FROM calculation WHERE rn_monetary = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.25) FROM calculation))
             AND monetary < (SELECT monetary FROM calculation WHERE rn_monetary = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.5) FROM calculation))
            THEN '2'
        WHEN monetary >= (SELECT monetary FROM calculation WHERE rn_monetary = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.5) FROM calculation))
             AND monetary < (SELECT monetary FROM calculation WHERE rn_monetary = (SELECT FLOOR(COUNT(DISTINCT(CustomerID))*0.75) FROM calculation))
            THEN '3'
        ELSE '4'
    END AS M
FROM calculation)




SELECT *, CONCAT(R, F, M) AS `group`
FROM result;


#mapping data

SELECT *,
    CONCAT(R, F, M) AS `group`, 
    COUNT(*) AS total_client,
    CASE 
        WHEN CONCAT(R, F, M) IN ('444', '443', '434', '344') THEN 'VIP'
        WHEN CONCAT(R, F, M) IN ('312', '311', '313', '314', '341', '342', '323', '321', '324', '332', '331', '333', '334', '343', '441', '433') THEN 'Loyal'
        WHEN CONCAT(R, F, M) IN ('114', '213', '231', '244', '214', '144', '243', '242', '241', '234', '233', '232', '224', '322', '412') THEN 'Potential'
        WHEN CONCAT(R, F, M) IN ('122', '132', '211', '212', '221', '222', '113', '143', '141', '142', '123', '223', '124', '133', '131') THEN 'No need to care'
        WHEN CONCAT(R, F, M) IN ('111', '112', '121', '134') THEN 'Lost'
        ELSE 'Other'
    END AS Customer_Type
FROM result
GROUP BY `group`

