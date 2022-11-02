# Salesforce Customer Data Platform: Calculated Insights Examples

*See the Salesforce Customer Data Platform (CDP) [Calculated Insights Help Section](https://help.salesforce.com/articleView?id=sf.c360_a_calculated_insights.htm&type=5) and [Trails on Trailhead](https://help.salesforce.com/s/search-result?language=en_US#q=calculated%20insights%20customer%20data%20platform&t=allResultsTab&sort=relevancy&f:@objecttype=[Trailhead]&f:@sflanguage=[en_US) for more details*

**Overview**

The Calculated Insights feature lets you define and calculate multidimensional metrics from your entire digital state stored in Salesforce CDP.

Your metrics can include Customer Lifetime Value (LTV), Most Viewed Categories, Customer Satisfaction Score (CSAT), Affinity Scores at the profile level, or any other desired specialized metrics. Marketers can use Calculated Insights to define segment criteria and personalization attributes for activation using metrics, dimensions, and filters. 

*This file contains query examples that can be used as templates when creating Calculated Insights in Salesforce CDP.*

Attached is a PDF file called "Data Schema" that shows the data relationships for Engagement and Order/Transaction tables used for some of the queries below. It is noted below the summary of each query whether it corresponds to this data schema specifically.

***Table of Contents***

*Example Queries: Beginner Complexity Level*
* Spend by Customer
* Spend by Customer and Product
* Count of Emails Opened for Each Unified Individual
* Recency, Frequency, and Monetary (RFM) Metrics for Each Unified Individual without Customer Buckets
* Lifetime Value (LTV) for Each Unified Individual
* Purchase Insights for Each Unified Individual
* Customer Rank by Spend for Each Unified Individual
* Customer Rank by Category Spend for Each Unified Individual
* Customer Rank by Category Purchase Count for Each Unified Individual
* Customer Rank by Category Item Purchase Count for Each Unified Individual  

*Useful Function Examples*

* Using NOT IN and WHERE Operators
* Using CASE Statements
* Using Streaming Insights with 5 Minute Aggregations  

*Example Queries: Intermediate to Advanced Complexity Level*

* Recency, Frequency, and Monetary (RFM) Metrics for Each Unified Individual with Customer Buckets
* Email Engagement Customer Buckets for Each Unified Individual
* Social Channel Affinity for Each Unified Individual
* Web, Mobile, and Email Engagement Scores (3 Queries)
* Beyond People Product Clusters_Analytics (see attached file)


***Example Queries***

**Spend by Customer**  

*Creates a dimension based on the Individual ID and a measure Customer Spend*

```
SELECT
    SUM(SALESORDER__dlm.grand_total_amount__c) as customer_spend__c,
    Individual__dlm.Id__c as custid__c
FROM
    SALESORDER__dlm
JOIN
    Individual__dlm
ON
    SALESORDER__dlm.partyid__c = Individual__dlm.Id__c 
GROUP BY
custid__c
```
| Measure            | Dimension   |
| -----------        | ----------- |
| customer_spend__c  | custid__c   |


**Spend by Customer and Product**  

*Creates a measure Customer Spend, a dimension based on Individual ID, and a dimension based on product name*

```
SELECT
    SUM(SALESORDER__dlm.grand_total_amount__c ) as customer_spend__c,
    PRODUCT__dlm.name__c as product__c,
    Individual__dlm.Id__c as custid__c
FROM
    PRODUCT__dlm
JOIN
    SALESORDERPRODUCT__dlm
    ON
        PRODUCT__dlm.productid__c=SALESORDERPRODUCT__dlm.productid__c
JOIN
    SALESORDER__dlm
    ON 
        SALESORDER__dlm.orderid__c=SALESORDERPRODUCT__dlm.orderid__c
JOIN
    Individual__dlm
    ON
        SALESORDER__dlm.partyid__c= Individual__dlm.Id__c 
GROUP BY
    custid__c, 
    product__c
```
| Measure            | Dimensions   |
| -----------        | -----------  |
| customer_spend__c  | custid__c    |
|                    | product__c   |


**Count of Emails Opened for Each Unified Individual**  

*Creates a dimension Unified Individual ID and a measure Email Open Count*

```
SELECT COUNT( EmailEngagement__dlm.Id__c) as email_open_count__c,
    UnifiedIndividual__dlm.Id__c as customer_id__c
FROM 
    EmailEngagement__dlm 
JOIN 
    IndividualIdentityLink__dlm 
ON 
    IndividualIdentityLink__dlm.SourceRecordId__c =  EmailEngagement__dlm.IndividualId__c
    and EmailEngagement__dlm.EngagementChannelActionId__c ='Open'
JOIN
    UnifiedIndividual__dlm 
ON
    UnifiedIndividual__dlm. Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c 
GROUP BY 
    customer_id__c
```
| Measure              | Dimension      |
| -----------          | -----------    |
| email_open_count__c  | customer_id__c |


**Recency, Frequency, and Monetary (RFM) Metrics for Each Unified Individual without Customer Buckets**  

*Creates a dimension Unified Individual ID and three measures for RFM as well as a measure for the combined RFM score*  

*See below for another version of this query that includes Customer Buckets based on RFM score called "Recency, Frequency, and Monetary (RFM) Metrics for Each Unified Individual with Customer Buckets"

```
SELECT sub2.cust_id__c as id__c, 
    First(sub2.rfm_recency__c*100 + sub2.rfm_frequency__c*10 +sub2.rfm_monetary__c) as rfm_combined__c,
    First(sub2.rfm_recency__c) as Recency__c,
    First(sub2.rfm_frequency__c) as Frequency__c, 
    First(sub2.rfm_monetary__c) as Monetary__c
    From ( 
        select UnifiedIndividual__dlm.Id__c as cust_id__c, 
        ntile(4) over (order by MAX(SALESORDER__dlm.checkout_date__c)) as rfm_recency__c, 
        ntile(4) over (order by count(SALESORDER__dlm.orderid__c)) as rfm_frequency__c, 
        ntile(4) over (order by avg(SALESORDER__dlm.grand_total_amount__c)) as rfm_monetary__c 
        FROM 
        SALESORDER__dlm 
            LEFT JOIN
                IndividualIdentityLink__dlm
            ON
                SALESORDER__dlm.partyid__c=IndividualIdentityLink__dlm.SourceRecordId__c
            LEFT Join
                UnifiedIndividual__dlm
            ON
                UnifiedIndividual__dlm.Id__c=IndividualIdentityLink__dlm.UnifiedRecordId__c
        GROUP BY 
        UnifiedIndividual__dlm.Id__c 
        ) as sub2 
GROUP BY 
sub2.cust_id__c
```
| Measures             | Dimension      |
| -----------          | -----------    |
| Recency__c           | cust_id__c     |
| Frequency__c         |                |
| Monetary__c          |                |
| rfm_combined__c      |                |


**Lifetime Value (LTV) for Each Unified Individual**  

*Creates dimensions Unified Individual ID, Purchase Hour, Product related dimensions such as Product Category, and Sales related dimensions such as Sales Channel. Creates dimension LTV based on the SUM of Grand Total Sales*  

*This query corresponds to the data schema in the attached PDF

```
SELECT
  SUM(ssot__SalesOrder__dlm.ssot__GrandTotalAmount__c) as LTV__c,
  UnifiedIndividual__dlm.ssot__Id__c as CustomerId__c,
  CDPHour(ssot__SalesOrder__dlm.ssot__PurchaseOrderDate__c) as PurchaseHour__c,
  ssot__GoodsProduct__dlm.Category__c as ProductCategory__c,
  ssot__SalesOrder__dlm.ssot__SalesChannelId__c as SalesChannel__c,
  ssot__SalesOrder__dlm.ssot__SalesStoreId__c as SalesStore__c,
  ssot__GoodsProduct__dlm.Subcategory__c as ProductSubCategory__c,
  ssot__GoodsProduct__dlm.Product_Name__c as ProductName__c,
  ssot__GoodsProduct__dlm.ssot__BrandId__c as Brand__c 
FROM
  ssot__SalesOrder__dlm 
  LEFT JOIN
    IndividualIdentityLink__dlm 
    ON ssot__SalesOrder__dlm.ssot__SoldToCustomerId__c = IndividualIdentityLink__dlm.SourceRecordId__c 
  LEFT JOIN
    UnifiedIndividual__dlm 
    ON IndividualIdentityLink__dlm.UnifiedRecordId__c = UnifiedIndividual__dlm.ssot__Id__c 
  LEFT JOIN
    ssot__SalesOrderProduct__dlm 
    on ssot__SalesOrderProduct__dlm.ssot__SalesOrderId__c = ssot__SalesOrder__dlm.ssot__OrderNumber__c 
  LEFT Join
    ssot__GoodsProduct__dlm 
    on ssot__SalesOrderProduct__dlm.ssot__ProductId__c = ssot__GoodsProduct__dlm.ssot__ProductSKU__c 
GROUP BY
  PurchaseHour__c,
  ProductCategory__c,
  CustomerId__c,
  SalesChannel__c,
  SalesStore__c,
  ProductSubCategory__c,
  ProductName__c,
  Brand__c
```
| Measure              | Dimensions           |
| -----------          | -----------          |
| LTV__c               | PurchaseHour__c      |   
|                      | ProductCategory__c   |
|                      | CustomerId__c        |
|                      | SalesChannel__c      |
|                      | SalesStore__c        |
|                      | ProductSubCategory__c|
|                      | ProductName__c       |
|                      | Brand__c             |


**Purchase Insights for Each Unified Individual**  

*Creates a dimension Unified Individual ID, Time Period based on the hour of purchase, product related dimensions such as Product Category, sales related dimensions such as Sales Channel. Creates measures such as Total Spend, Average Order Amount, Total Number of Orders, Lowest Order Amount, and Highest Order Amount*  

*This query corresponds to the data schema in the attached PDF

```
SELECT
  SUM(ssot__SalesOrder__dlm.ssot__GrandTotalAmount__c) as TotalSpend__c,
  AVG(ssot__SalesOrder__dlm.ssot__GrandTotalAmount__c) as AvgOrderAmount__c,
  COUNT(ssot__SalesOrder__dlm.ssot__Id__c) as TotalOrders__c,
  MIN(ssot__SalesOrder__dlm.ssot__GrandTotalAmount__c) as LowestOrderAmount__c,
  MAX(ssot__SalesOrder__dlm.ssot__GrandTotalAmount__c) as HighestOrderAmount__c,
  CDPHour(ssot__SalesOrder__dlm.ssot__PurchaseOrderDate__c) as TimePeriod__c,
  UnifiedIndividual__dlm.ssot__Id__c as CustomerId__c,
  ssot__SalesOrder__dlm.ssot__SalesChannelId__c as SalesChannel__c,
  ssot__SalesOrder__dlm.Payment_Method__c as PaymentMethod__c,
  ssot__SalesOrder__dlm.ssot__SalesStoreId__c as SalesStore__c,
  ssot__GoodsProduct__dlm.Category__c as ProductCategory__c,
  ssot__GoodsProduct__dlm.Subcategory__c as ProductSubCategory__c,
  ssot__GoodsProduct__dlm.Product_Name__c as ProductName__c,
  ssot__GoodsProduct__dlm.ssot__BrandId__c as Brand__c 
FROM
  ssot__SalesOrder__dlm 
  LEFT JOIN
    IndividualIdentityLink__dlm 
    ON ssot__SalesOrder__dlm.ssot__SoldToCustomerId__c = IndividualIdentityLink__dlm.SourceRecordId__c 
  LEFT JOIN
    UnifiedIndividual__dlm 
    ON IndividualIdentityLink__dlm.UnifiedRecordId__c = UnifiedIndividual__dlm.ssot__Id__c 
  LEFT JOIN
    ssot__SalesOrderProduct__dlm 
    on ssot__SalesOrderProduct__dlm.ssot__SalesOrderId__c = ssot__SalesOrder__dlm.ssot__OrderNumber__c 
  LEFT Join
    ssot__GoodsProduct__dlm 
    on ssot__SalesOrderProduct__dlm.ssot__ProductId__c = ssot__GoodsProduct__dlm.ssot__ProductSKU__c 
GROUP BY
  CustomerId__c,
  SalesChannel__c,
  PaymentMethod__c,
  SalesStore__c,
  ProductCategory__c,
  ProductSubCategory__c,
  ProductName__c,
  TimePeriod__c,
  Brand__c
```
| Measures             | Dimensions           |
| -----------          | -----------          |
| TotalSpend__c        | CustomerId__c        |
| AvgOrderAmount__c    | SalesChannel__c      |
| TotalOrders__c       | PaymentMethod__c     |
| LowestOrderAmount__c | SalesStore__c        |
| HighestOrderAmount__c| SalesStore__c        |
|                      | ProductCategory__c   |
|                      | ProductSubCategory__c|
|                      | ProductName__c       |
|                      | TimePeriod__c        |
|                      | Brand__c             |


**Customer Rank by Spend for Each Unified Individual**  

*Creates a dimension Unified Individual ID. Creates three rank measures based on the total sales amount. The measures are Customer Rank based on Row Number, Customer Rank based on the rank function, and Customer Dense Rank based on the dense rank function*  

*See below for a version of this query where you can segment by Product Category  

*This query corresponds to the data schema in the attached PDF

```
SELECT
  UnifiedIndividual__dlm.ssot__Id__c AS Unified_Individual__c,
  ROW_NUMBER() OVER ( 
ORDER BY
  SUM(ssot__SalesOrder__dlm.ssot__GrandTotalAmount__c) desc) AS Customer_Rank__c,
  DENSE_RANK() OVER ( 
ORDER BY
  SUM(ssot__SalesOrder__dlm.ssot__GrandTotalAmount__c) desc) AS Customer_Stat_Dense_Rank__c,
  RANK() OVER ( 
ORDER BY
  SUM(ssot__SalesOrder__dlm.ssot__GrandTotalAmount__c) desc) AS Customer_Stat_Rank__c 
FROM
  UnifiedIndividual__dlm 
  INNER JOIN
    IndividualIdentityLink__dlm 
    ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c 
  INNER JOIN
    ssot__SalesOrder__dlm 
    ON IndividualIdentityLink__dlm.SourceRecordId__c = ssot__SalesOrder__dlm.ssot__SoldToCustomerId__c 
  LEFT JOIN
    ssot__SalesOrderProduct__dlm 
    on ssot__SalesOrder__dlm.ssot__Id__c = ssot__SalesOrderProduct__dlm.ssot__SalesOrderId__c 
GROUP BY
  Unified_Individual__c
```
| Measure                    | Dimension            |
| -----------                | -----------          |
| Customer_Rank__c           | Unified_Individual__c|
| Customer_Stat_Dense_Rank__c|                      |
| Customer_Stat_Rank__c      |                      |


**Customer Rank by Category Spend for Each Unified Individual**  

*This is the same as Customer Rank by Spend, but adds a dimension for Product Category. Creates a dimension Unified Individual ID and Product Category. Creates three rank measures based on the total sales amount. The measures are Customer Rank based on Row Number, Customer Rank based on the rank function, and Customer Dense Rank based on the dense rank function. Note that all dimensions must be selected in segmentation when using complex queries such as Row Number and Rank/Dense Rank*  

*This query corresponds to the data schema in the attached PDF

```
SELECT
  UnifiedIndividual__dlm.ssot__Id__c AS Unified_Individual__c,
  ROW_NUMBER() OVER ( 
ORDER BY
  SUM(ssot__SalesOrder__dlm.ssot__GrandTotalAmount__c) desc) AS Customer_Rank__c,
  DENSE_RANK() OVER ( 
ORDER BY
  SUM(ssot__SalesOrder__dlm.ssot__GrandTotalAmount__c) desc) AS Customer_Stat_Dense_Rank__c,
  RANK() OVER ( 
ORDER BY
  SUM(ssot__SalesOrder__dlm.ssot__GrandTotalAmount__c) desc) AS Customer_Stat_Rank__c,
  ssot__GoodsProduct__dlm.Category__c AS Product_Category__c 
FROM
  UnifiedIndividual__dlm 
  INNER JOIN
    IndividualIdentityLink__dlm 
    ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c 
  INNER JOIN
    ssot__SalesOrder__dlm 
    ON IndividualIdentityLink__dlm.SourceRecordId__c = ssot__SalesOrder__dlm.ssot__SoldToCustomerId__c 
  LEFT JOIN
    ssot__SalesOrderProduct__dlm 
    on ssot__SalesOrder__dlm.ssot__Id__c = ssot__SalesOrderProduct__dlm.ssot__SalesOrderId__c 
  LEFT Join
    ssot__GoodsProduct__dlm 
    on ssot__SalesOrderProduct__dlm.ssot__ProductId__c = ssot__GoodsProduct__dlm.ssot__Id__c 
GROUP BY
  Unified_Individual__c,
  Product_Category__c
```
| Measures                   | Dimensions           |
| -----------                | -----------          |
| Customer_Rank__c           | Unified_Individual__c|
| Customer_Stat_Rank__c      | Product_Category__c  |
| Customer_Stat_Dense_Rank__c|                      |


**Customer Rank by Category Purchase Count for Each Unified Individual**  

*Creates a dimension Unified Individual ID and Product Category. Creates three rank measures based on the count of sales orders. The measures are Customer Rank based on Row Number, Customer Rank based on the rank function, and Customer Dense Rank based on the dense rank function. Note that all dimensions must be selected in segmentation when using complex queries such as Row Number and Rank/Dense Rank*  

*This query corresponds to the data schema in the attached PDF

```
SELECT
  UnifiedIndividual__dlm.ssot__Id__c AS Unified_Individual__c,
  ROW_NUMBER() OVER ( 
ORDER BY
  COUNT(ssot__SalesOrder__dlm.ssot__Id__c) desc) AS Customer_Rank__c,
  DENSE_RANK() OVER ( 
ORDER BY
  COUNT(ssot__SalesOrder__dlm.ssot__Id__c) desc) AS Customer_Stat_Dense_Rank__c,
  RANK() OVER ( 
ORDER BY
  COUNT(ssot__SalesOrder__dlm.ssot__Id__c) desc) AS Customer_Stat_Rank__c,
  ssot__GoodsProduct__dlm.Category__c AS Product_Category__c 
FROM
  UnifiedIndividual__dlm 
  INNER JOIN
    IndividualIdentityLink__dlm 
    ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c 
  INNER JOIN
    ssot__SalesOrder__dlm 
    ON IndividualIdentityLink__dlm.SourceRecordId__c = ssot__SalesOrder__dlm.ssot__SoldToCustomerId__c 
  LEFT JOIN
    ssot__SalesOrderProduct__dlm 
    on ssot__SalesOrder__dlm.ssot__Id__c = ssot__SalesOrderProduct__dlm.ssot__SalesOrderId__c 
  LEFT Join
    ssot__GoodsProduct__dlm 
    on ssot__SalesOrderProduct__dlm.ssot__ProductId__c = ssot__GoodsProduct__dlm.ssot__Id__c 
GROUP BY
  Unified_Individual__c,
  Product_Category__c
```
| Measures                   | Dimensions           |
| -----------                | -----------          |
| Customer_Rank__c           | Unified_Individual__c|
| Customer_Stat_Rank__c      | Product_Category__c  |
| Customer_Stat_Dense_Rank__c|                      |


**Customer Rank by Category Item Purchase Count for Each Unified Individual**  

*Creates a dimension Unified Individual ID and Product Category. Creates three rank measures based on the count of Product SKUs purchased. The measures are Customer Rank based on Row Number, Customer Rank based on the rank function, and Customer Dense Rank based on the dense rank function. Note that all dimensions must be selected in segmentation when using complex queries such as Row Number and Rank/Dense Rank*  

*This query corresponds to the data schema in the attached PDF

```
SELECT
  UnifiedIndividual__dlm.ssot__Id__c AS Unified_Individual__c,
  ROW_NUMBER() OVER ( 
ORDER BY
  COUNT(ssot__GoodsProduct__dlm.ssot__ProductSKU__c) desc) AS Customer_Rank__c,
  DENSE_RANK() OVER ( 
ORDER BY
  COUNT(ssot__GoodsProduct__dlm.ssot__ProductSKU__c) desc) AS Customer_Stat_Dense_Rank__c,
  RANK() OVER ( 
ORDER BY
  COUNT(ssot__GoodsProduct__dlm.ssot__ProductSKU__c) desc) AS Customer_Stat_Rank__c,
  ssot__GoodsProduct__dlm.Category__c AS Product_Category__c 
FROM
  UnifiedIndividual__dlm 
  INNER JOIN
    IndividualIdentityLink__dlm 
    ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c 
  INNER JOIN
    ssot__SalesOrder__dlm 
    ON IndividualIdentityLink__dlm.SourceRecordId__c = ssot__SalesOrder__dlm.ssot__SoldToCustomerId__c 
  LEFT JOIN
    ssot__SalesOrderProduct__dlm 
    on ssot__SalesOrder__dlm.ssot__Id__c = ssot__SalesOrderProduct__dlm.ssot__SalesOrderId__c 
  LEFT Join
    ssot__GoodsProduct__dlm 
    on ssot__SalesOrderProduct__dlm.ssot__ProductId__c = ssot__GoodsProduct__dlm.ssot__Id__c 
GROUP BY
  Unified_Individual__c,
  Product_Category__c
```
| Measures                   | Dimensions           |
| -----------                | -----------          |
| Customer_Rank__c           | Unified_Individual__c|
| Customer_Stat_Rank__c      | Product_Category__c  |
| Customer_Stat_Dense_Rank__c|                      |


**Using NOT IN and WHERE Operators**  

*Creates a dimension Unified Individual ID and a measure of average grand total sales where the Sales Order Customer ID is "NOT IN" the Individual table*  

*This query corresponds to the data schema in the attached PDF

```
SELECT 
    avg( ssot__SalesOrder__dlm.ssot__GrandTotalAmount__c ) as avg__c, ssot__SalesOrder__dlm.ssot__SoldToCustomerId__c as customer_id__c 
FROM 
    ssot__SalesOrder__dlm where ssot__SalesOrder__dlm.ssot__SoldToCustomerId__c NOT IN (select ssot__Individual__dlm.ssot__Id__c as Id from ssot__Individual__dlm 
WHERE 
    ssot__Individual__dlm.Loyalty_Reward_Points__c > 10 ) 
GROUP BY
 customer_id__c
```
| Measure              | Dimension      |
| -----------          | -----------    |
| avg__c               | customer_id__c | 


**Using CASE Statements**  

*Creates a dimension Unified Individual ID and a bucket created with the CASE function that is based on a driver's safety level depending on how many times they didn't have their hands on the steering wheel*

```
Select 
  CASE WHEN SUM(S.no_hands_on_wheel_count__c) > 20 THEN 'Extremely Unsafe' WHEN SUM(S.no_hands_on_wheel_count__c) > 15 
  and SUM(S.no_hands_on_wheel_count__c)<= 20 THEN 'Frequently Unsafe' WHEN SUM(S.no_hands_on_wheel_count__c) > 10 
  and SUM(S.no_hands_on_wheel_count__c)<= 15 THEN 'Somewhat Unsafe' WHEN SUM(S.no_hands_on_wheel_count__c) > 5 
  and SUM(S.no_hands_on_wheel_count__c)<= 10 THEN 'Somewhat Safe' WHEN SUM(S.no_hands_on_wheel_count__c) > 3 
  and SUM(S.no_hands_on_wheel_count__c)<= 5 THEN 'Safe' WHEN SUM(S.no_hands_on_wheel_count__c) > 0 
  and SUM(S.no_hands_on_wheel_count__c)<= 3 THEN 'Extremely Safe' end as driver_safety_score__c, 
  S.customer_id__c as driver__c 
FROM 
  (
    select 
      COUNT(
        VehicleTelematics__dlm.nohandsonwheel__c
      ) as no_hands_on_wheel_count__c, 
      UnifiedIndividual__dlm.ssot__Id__c as customer_id__c 
    FROM 
      VehicleTelematics__dlm 
      join Vehicle__dlm on (
        VehicleTelematics__dlm.vehicleid__c = Vehicle__dlm.id__c
      ) 
      left outer join IndividualIdentityLink__dlm on (
        VehicleTelematics__dlm.maid__c = IndividualIdentityLink__dlm.SourceRecordId__c
      ) 
      join UnifiedIndividual__dlm on (
        IndividualIdentityLink__dlm.UnifiedRecordId__c = UnifiedIndividual__dlm.ssot__Id__c
      ) 
    group by 
      UnifiedIndividual__dlm.ssot__Id__c
  ) as S 
Group by 
  driver__c
```
| Measure               | Dimension      |
| -----------           | -----------    |
| driver_safety_score__c| driver__c      |


**Using Streaming Insights with 5 Minute Aggregations**  

*Creates dimensions Mobile app product ID and Mobile app events that occur in 5 minute windows. Measures are the SUM of order quantity as well as window start and window end*

```
SELECT 
  SUM(
    MobileApp_RT_Events__dlm.productPurchaseWeb_orderQuantity__c
  ) as order_placed__c, 
  MobileApp_RT_Events__dlm.AddToCartWeb_productId__c as product__c, 
  WINDOW.START as windowstart__c, 
  WINDOW.END as windowend__c 
FROM 
  MobileApp_RT_Events__dlm 
GROUP BY 
  window(
    MobileApp_RT_Events__dlm.dateTime__c, 
    '5 MINUTE'
  ), 
  product__c
```
| Measures              | Dimension      |
| -----------           | -----------    |
| order_placed__c       | product__c     |
|                       | windowstart__c |
|                       | windowend__c   |


**Recency, Frequency, and Monetary (RFM) Metrics for Each Unified Individual with Customer Buckets**  

*Creates a dimension Unified Individual ID and a Customer Bucket based on RFM score. Creates three measures for RFM as well as a measure for the combined RFM score*  

*This query corresponds to the data schema in the attached PDF

```
SELECT
  sub2.CustomerId__c as CustomerId__c,
  CASE
    WHEN
      Max(sub2.rfm_recency__c*100 + sub2.rfm_frequency__c*10 + sub2.rfm_monetary__c) = 111 
    THEN
      'Best Customers' 
    WHEN
      Max(sub2.rfm_recency__c*100 + sub2.rfm_frequency__c*10 + sub2.rfm_monetary__c) = 141 
    THEN
      'New Spenders' 
    WHEN
      Max(sub2.rfm_recency__c*100 + sub2.rfm_frequency__c*10 + sub2.rfm_monetary__c) = 311 
    THEN
      'Almost Lost' 
    WHEN
      Max(sub2.rfm_recency__c*100 + sub2.rfm_frequency__c*10 + sub2.rfm_monetary__c) = 411 
    THEN
      'Lost Customers' 
    WHEN
      Max(sub2.rfm_recency__c*100 + sub2.rfm_frequency__c*10 + sub2.rfm_monetary__c) = 444 
    THEN
      'Lost Low Value Customers' 
    WHEN
      Max(sub2.rfm_frequency__c*10 + sub2.rfm_monetary__c) = 14 
    THEN
      'Loyal Joes and Janes' 
    WHEN
      Max(sub2.rfm_frequency__c*10 + sub2.rfm_monetary__c) = 41 
    THEN
      'Splurgers' 
    WHEN
      Max(sub2.rfm_frequency__c) = 1 
    THEN
      'Loyal Customers' 
    WHEN
      Max(sub2.rfm_monetary__c) = 1 
    THEN
      'Big Spenders' 
    Else
      'Others' 
  END
  as RFM_SegmentName__c, Max(sub2.rfm_recency__c*100 + sub2.rfm_frequency__c*10 + sub2.rfm_monetary__c) as RFM_Combined__c, Max(sub2.rfm_recency__c) as Recency__c, Max(sub2.rfm_frequency__c) as Frequency__c, Max(sub2.rfm_monetary__c) as Monetary__c 
From
  (
    SELECT
      UnifiedIndividual__dlm.ssot__Id__c as CustomerId__c,
      ntile(4) over (
    order by
      MAX(ssot__SalesOrder__dlm.ssot__PurchaseOrderDate__c)) as rfm_recency__c,
      ntile(4) over (
    order by
      count(ssot__SalesOrder__dlm.ssot__Id__c) DESC) as rfm_frequency__c,
      ntile(4) over (
    order by
      SUM(ssot__SalesOrder__dlm.ssot__GrandTotalAmount__c) DESC) as rfm_monetary__c 
    FROM
      UnifiedIndividual__dlm 
      LEFT JOIN
        IndividualIdentityLink__dlm 
        ON IndividualIdentityLink__dlm.UnifiedRecordId__c = UnifiedIndividual__dlm.ssot__Id__c 
      LEFT Join
        ssot__SalesOrder__dlm 
        ON IndividualIdentityLink__dlm.SourceRecordId__c = ssot__SalesOrder__dlm.ssot__SoldToCustomerId__c 
    GROUP BY
      UnifiedIndividual__dlm.ssot__Id__c 
  )
  as sub2 
GROUP BY
  CustomerId__c
```
| Measure              | Dimension      |
| -----------          | -----------    |
| RFM_SegmentName__c   | CustomerId__c  |
| RFM_Combined__c      |                |
| Recency__c           |                |
| Frequency__c         |                |
| Monetary__c          |                |


**Email Engagement Customer Buckets for Each Unified Individual**  

*Creates dimensions Unified Individual ID and Customer Email Engagement Bucket based on NTILE(3) of the sum of email opens and clicks. Creates measures Open Rate and Click Rate*  

*This query corresponds to the data schema in the attached PDF

```
SELECT
  CASE
    WHEN
      (
        NTILE (3) over ( 
      ORDER BY
        SUM(sub1.EmailOpenCount__c + sub1.EmailClickCount__c) desc) 
      )
      = 3 
    THEN
      'Low' 
    WHEN
      (
        NTILE (3) over ( 
      ORDER BY
        SUM(sub1.EmailOpenCount__c + sub1.EmailClickCount__c)desc) 
      )
      = 2 
    THEN
      'Medium' 
    WHEN
      (
        NTILE (3) over ( 
      ORDER BY
        SUM(sub1.EmailOpenCount__c + sub1.EmailClickCount__c)desc) 
      )
      = 1 
    then
      'High' 
  end
  AS Customer_Engagement_Bucket__c, SUM(sub1.EmailOpenCount__c) / SUM(sub1.EmailSendCount__c) AS Open_Rate__c, SUM(sub1.EmailClickCount__c) / SUM(sub1.EmailSendCount__c) AS Click_Rate__c, sub1.UnifiedIndividualId__c AS Unified_Individual__c 
FROM
  (
    SELECT
      SUM( 
      CASE
        WHEN
          ssot__EmailEngagement__dlm.ssot__EngagementChannelActionId__c = 'Open' 
        THEN
          1 
        ELSE
          0 
      end
) AS EmailOpenCount__c, SUM( 
      CASE
        WHEN
          ssot__EmailEngagement__dlm.ssot__EngagementChannelActionId__c = 'Click' 
        THEN
          1 
        ELSE
          0 
      end
) AS EmailClickCount__c, SUM( 
      CASE
        WHEN
          ssot__EmailEngagement__dlm.ssot__EngagementChannelActionId__c = 'Send' 
        THEN
          1 
        ELSE
          0 
      end
) AS EmailSendCount__c, UnifiedIndividual__dlm.ssot__Id__c AS UnifiedIndividualId__c 
    FROM
      UnifiedIndividual__dlm 
      INNER JOIN
        IndividualIdentityLink__dlm 
        ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c 
      INNER JOIN
        ssot__EmailEngagement__dlm 
        ON IndividualIdentityLink__dlm.SourceRecordId__c = ssot__EmailEngagement__dlm.ssot__IndividualId__c 
    GROUP BY
      UnifiedIndividual__dlm.ssot__Id__c 
  )
  AS sub1 
GROUP BY
  Unified_Individual__c 
HAVING
  SUM(sub1.EmailOpenCount__c + sub1.EmailClickCount__c) > 0
```
| Measure                      | Dimension            |
| -----------                  | -----------          |
| Customer_Engagement_Bucket__c| Unified_Individual__c|
| Open_Rate__c                 |                      |
| Click_Rate__c                |                      |


**Social Channel Affinity for Each Unified Individual**  

*Creates dimensions Unified Individual ID and Social Channel Affinity Source based on the user's most frequent social channel engagement. Creates measure Social Channel Affinity Score from 0-100 based on how many times a user engaged with the social channel they have the most affinity for*   

*This query corresponds to the data schema in the attached PDF

```
Select
  userScore.Unified_Individual__c as Unified_Individual__c,
  userScore.socialchannelaffinitysource__c as Social_Channel_Affinity_Source__c,
  (
    FIRST(userScore.Social_Channel_Affinity_Count__c) / Max(totalMax.totalmaxsocialchannelaffinitycount__c)
  )
  *100 as Social_Channel_Affinity_Score__c 
FROM
  (
    Select
      sub2.Unified_Individual__c as Unified_Individual__c,
      FIRST(sub2.socialchannelaffinitycount__c) as Social_Channel_Affinity_Count__c,
      CASE
        WHEN
          (
            GREATEST(SUM(sub2.facebooksourcecount__c), SUM(sub2.googlesourcecount__c), SUM(sub2.twittersourcecount__c), SUM(sub2.pinterestsourcecount__c), SUM(sub2.instagramsourcecount__c), SUM(sub2.directsourcecount__c)) = SUM(sub2.facebooksourcecount__c) 
            AND GREATEST(SUM(sub2.googlesourcecount__c), SUM(sub2.twittersourcecount__c), SUM(sub2.pinterestsourcecount__c), SUM(sub2.instagramsourcecount__c), SUM(sub2.directsourcecount__c)) < SUM(sub2.facebooksourcecount__c) 
          )
        THEN
          'Facebook' 
        WHEN
          (
            GREATEST(SUM(sub2.facebooksourcecount__c), SUM(sub2.googlesourcecount__c), SUM(sub2.twittersourcecount__c), SUM(sub2.pinterestsourcecount__c), SUM(sub2.instagramsourcecount__c), SUM(sub2.directsourcecount__c)) = SUM(sub2.googlesourcecount__c) 
            AND GREATEST(SUM(sub2.facebooksourcecount__c), SUM(sub2.twittersourcecount__c), SUM(sub2.pinterestsourcecount__c), SUM(sub2.instagramsourcecount__c), SUM(sub2.directsourcecount__c)) < SUM(sub2.googlesourcecount__c) 
          )
        THEN
          'Google' 
        WHEN
          (
            GREATEST(SUM(sub2.facebooksourcecount__c), SUM(sub2.googlesourcecount__c), SUM(sub2.twittersourcecount__c), SUM(sub2.pinterestsourcecount__c), SUM(sub2.instagramsourcecount__c), SUM(sub2.directsourcecount__c)) = SUM(sub2.twittersourcecount__c) 
            AND GREATEST(SUM(sub2.googlesourcecount__c), SUM(sub2.facebooksourcecount__c), SUM(sub2.pinterestsourcecount__c), SUM(sub2.instagramsourcecount__c), SUM(sub2.directsourcecount__c)) < SUM(sub2.twittersourcecount__c) 
          )
        THEN
          'Twitter' 
        WHEN
          (
            GREATEST(SUM(sub2.facebooksourcecount__c), SUM(sub2.googlesourcecount__c), SUM(sub2.twittersourcecount__c), SUM(sub2.pinterestsourcecount__c), SUM(sub2.instagramsourcecount__c), SUM(sub2.directsourcecount__c)) = SUM(sub2.pinterestsourcecount__c) 
            AND GREATEST(SUM(sub2.googlesourcecount__c), SUM(sub2.twittersourcecount__c), SUM(sub2.facebooksourcecount__c), SUM(sub2.instagramsourcecount__c), SUM(sub2.directsourcecount__c)) < SUM(sub2.pinterestsourcecount__c) 
          )
        THEN
          'Pinterest' 
        WHEN
          (
            GREATEST(SUM(sub2.facebooksourcecount__c), SUM(sub2.googlesourcecount__c), SUM(sub2.twittersourcecount__c), SUM(sub2.pinterestsourcecount__c), SUM(sub2.instagramsourcecount__c), SUM(sub2.directsourcecount__c)) = SUM(sub2.instagramsourcecount__c) 
            AND GREATEST(SUM(sub2.googlesourcecount__c), SUM(sub2.twittersourcecount__c), SUM(sub2.pinterestsourcecount__c), SUM(sub2.facebooksourcecount__c), SUM(sub2.directsourcecount__c)) < SUM(sub2.instagramsourcecount__c) 
          )
        THEN
          'Instagram' 
        WHEN
          (
            GREATEST(SUM(sub2.facebooksourcecount__c), SUM(sub2.googlesourcecount__c), SUM(sub2.twittersourcecount__c), SUM(sub2.pinterestsourcecount__c), SUM(sub2.instagramsourcecount__c), SUM(sub2.directsourcecount__c)) = SUM(sub2.directsourcecount__c) 
            AND GREATEST(SUM(sub2.googlesourcecount__c), SUM(sub2.twittersourcecount__c), SUM(sub2.pinterestsourcecount__c), SUM(sub2.instagramsourcecount__c), SUM(sub2.facebooksourcecount__c)) < SUM(sub2.directsourcecount__c) 
          )
        THEN
          'Direct' 
        ELSE
          'Tie' 
      end
      as socialchannelaffinitysource__c 
    FROM
      (
        Select
          sub1.Unified_Individual__c as Unified_Individual__c,
          FIRST(sub1.facebooksourcecount__c) as facebooksourcecount__c,
          FIRST(sub1.googlesourcecount__c) as googlesourcecount__c,
          FIRST(sub1.twittersourcecount__c) as twittersourcecount__c,
          FIRST(sub1.pinterestsourcecount__c) as pinterestsourcecount__c,
          FIRST(sub1.instagramsourcecount__c) as instagramsourcecount__c,
          FIRST(sub1.directsourcecount__c) as directsourcecount__c,
          FIRST(GREATEST (sub1.facebooksourcecount__c, sub1.googlesourcecount__c, sub1.twittersourcecount__c, sub1.pinterestsourcecount__c, sub1.instagramsourcecount__c, sub1.directsourcecount__c)) as socialchannelaffinitycount__c 
        From
          (
            Select
              UnifiedIndividual__dlm.ssot__Id__c as Unified_Individual__c,
              SUM( 
              CASE
                WHEN
                  ssot__WebsiteEngagement__dlm.Referrer_Source__c = 'Facebook' 
                  or ssot__DeviceApplicationEngagement__dlm.Referrer_Source__c = 'Facebook' 
                then
                  1 
                else
                  0 
              end
) as facebooksourcecount__c, SUM( 
              CASE
                WHEN
                  ssot__WebsiteEngagement__dlm.Referrer_Source__c = 'Google' 
                  or ssot__DeviceApplicationEngagement__dlm.Referrer_Source__c = 'Google' 
                then
                  1 
                else
                  0 
              end
) as googlesourcecount__c, SUM( 
              CASE
                WHEN
                  ssot__WebsiteEngagement__dlm.Referrer_Source__c = 'Twitter' 
                  or ssot__DeviceApplicationEngagement__dlm.Referrer_Source__c = 'Twitter' 
                then
                  1 
                else
                  0 
              end
) as twittersourcecount__c, SUM( 
              CASE
                WHEN
                  ssot__WebsiteEngagement__dlm.Referrer_Source__c = 'Pinterest' 
                  or ssot__DeviceApplicationEngagement__dlm.Referrer_Source__c = 'Pinterest' 
                then
                  1 
                else
                  0 
              end
) as pinterestsourcecount__c, SUM( 
              CASE
                WHEN
                  ssot__WebsiteEngagement__dlm.Referrer_Source__c = 'Instagram' 
                  or ssot__DeviceApplicationEngagement__dlm.Referrer_Source__c = 'Instagram' 
                then
                  1 
                else
                  0 
              end
) as instagramsourcecount__c, SUM( 
              CASE
                WHEN
                  ssot__WebsiteEngagement__dlm.Referrer_Source__c = 'Direct' 
                  or ssot__DeviceApplicationEngagement__dlm.Referrer_Source__c = 'Direct' 
                then
                  1 
                else
                  0 
              end
) as directsourcecount__c 
            FROM
              UnifiedIndividual__dlm 
              INNER JOIN
                IndividualIdentityLink__dlm 
                ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c 
              LEFT JOIN
                ssot__DeviceApplicationEngagement__dlm 
                ON ssot__DeviceApplicationEngagement__dlm.ssot__IndividualId__c = IndividualIdentityLink__dlm.SourceRecordId__c 
              LEFT JOIN
                ssot__WebsiteEngagement__dlm 
                ON ssot__WebsiteEngagement__dlm.ssot__IndividualId__c = IndividualIdentityLink__dlm.SourceRecordId__c 
            GROUP BY
              UnifiedIndividual__dlm.ssot__Id__c 
          )
          as sub1 
        GROUP BY
          sub1.Unified_Individual__c 
      )
      as sub2 
    GROUP BY
      sub2.Unified_Individual__c
  )
  AS userScore 
  FULL JOIN
    (
      SELECT
        MAX(sub2.socialchannelaffinitycount__c) as totalmaxsocialchannelaffinitycount__c 
      FROM
        (
          Select
            sub1.Unified_Individual__c as Unified_Individual__c,
            FIRST(GREATEST (sub1.facebooksourcecount__c, sub1.googlesourcecount__c, sub1.twittersourcecount__c, sub1.pinterestsourcecount__c, sub1.instagramsourcecount__c, sub1.directsourcecount__c)) as socialchannelaffinitycount__c 
          From
            (
              Select
                UnifiedIndividual__dlm.ssot__Id__c as Unified_Individual__c,
                SUM( 
                CASE
                  WHEN
                    ssot__WebsiteEngagement__dlm.Referrer_Source__c = 'Facebook' 
                    or ssot__DeviceApplicationEngagement__dlm.Referrer_Source__c = 'Facebook' 
                  then
                    1 
                  else
                    0 
                end
) as facebooksourcecount__c, SUM( 
                CASE
                  WHEN
                    ssot__WebsiteEngagement__dlm.Referrer_Source__c = 'Google' 
                    or ssot__DeviceApplicationEngagement__dlm.Referrer_Source__c = 'Google' 
                  then
                    1 
                  else
                    0 
                end
) as googlesourcecount__c, SUM( 
                CASE
                  WHEN
                    ssot__WebsiteEngagement__dlm.Referrer_Source__c = 'Twitter' 
                    or ssot__DeviceApplicationEngagement__dlm.Referrer_Source__c = 'Twitter' 
                  then
                    1 
                  else
                    0 
                end
) as twittersourcecount__c, SUM( 
                CASE
                  WHEN
                    ssot__WebsiteEngagement__dlm.Referrer_Source__c = 'Pinterest' 
                    or ssot__DeviceApplicationEngagement__dlm.Referrer_Source__c = 'Pinterest' 
                  then
                    1 
                  else
                    0 
                end
) as pinterestsourcecount__c, SUM( 
                CASE
                  WHEN
                    ssot__WebsiteEngagement__dlm.Referrer_Source__c = 'Instagram' 
                    or ssot__DeviceApplicationEngagement__dlm.Referrer_Source__c = 'Instagram' 
                  then
                    1 
                  else
                    0 
                end
) as instagramsourcecount__c, SUM( 
                CASE
                  WHEN
                    ssot__WebsiteEngagement__dlm.Referrer_Source__c = 'Direct' 
                    or ssot__DeviceApplicationEngagement__dlm.Referrer_Source__c = 'Direct' 
                  then
                    1 
                  else
                    0 
                end
) as directsourcecount__c 
              FROM
                UnifiedIndividual__dlm 
                INNER JOIN
                  IndividualIdentityLink__dlm 
                  ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c 
                LEFT JOIN
                  ssot__DeviceApplicationEngagement__dlm 
                  ON ssot__DeviceApplicationEngagement__dlm.ssot__IndividualId__c = IndividualIdentityLink__dlm.SourceRecordId__c 
                LEFT JOIN
                  ssot__WebsiteEngagement__dlm 
                  ON ssot__WebsiteEngagement__dlm.ssot__IndividualId__c = IndividualIdentityLink__dlm.SourceRecordId__c 
              GROUP BY
                UnifiedIndividual__dlm.ssot__Id__c 
            )
            as sub1 
          GROUP BY
            sub1.Unified_Individual__c 
        )
        as sub2 
    )
    AS totalMax 
    ON userScore.Unified_Individual__c <> '' 
    AND totalMax.totalmaxsocialchannelaffinitycount__c <> - 1000 
Group by
  Unified_Individual__c, Social_Channel_Affinity_Source__c
```
| Measure                         | Dimensions                       |
| -----------                     | -----------                      |
| Social_Channel_Affinity_Score__c| Unified_Individual__c            |
|                                 | Social_Channel_Affinity_Source__c|


**Web, Mobile, and Email Engagement Scores (3 Queries)**  

*Creates dimension Unified Individual as well as product related dimensions like Product Category. Creates measure Web Engagement Score (and mobile and email scores, respectively). Note: Email Engagement query is slightly different than web and mobile to account for engagement based on only opens and clicks and doesn't include product related dimensions since the schema doesn't directly relate to the product table*  

*These queries correspond to the data schema in the attached PDF  

| Measure                         | Dimensions            |
| -----------                     | -----------           |
| Web_Engagement_Score__c         | Unified_Individual__c |
| (or Mobile or Email Scores)     | Content_Category__c   |
|                                 | Product_Category__c   |
|                                 | Product_SubCategory__c|
|                                 | Product_Name__c       |
|                                 | Brand__c              |

*Web Engagement Score*
```
 SELECT
  userScore.Unified_Individual__c as Unified_Individual__c,
  (
    FIRST(userScore.Web_Engagement_Count__c) / Max(totalMax.totalmaxwebengagementcount__c) 
  )
  *100 as Web_Engagement_Score__c,
  userScore.Content_Category__c as Content_Category__c,
  userScore.Product_Category__c as Product_Category__c,
  userScore.Product_SubCategory__c as Product_SubCategory__c,
  userScore.Product_Name__c as Product_Name__c,
  userScore.Brand__c as Brand__c 
FROM
  (
    SELECT
      sub1.Unified_Individual__c as Unified_Individual__c,
      sub1.Content_Category__c as Content_Category__c,
      sub1.Product_Category__c as Product_Category__c,
      sub1.Product_SubCategory__c as Product_SubCategory__c,
      sub1.Product_Name__c as Product_Name__c,
      sub1.Brand__c as Brand__c,
      SUM( 
      CASE
        when
          isnull(sub1.Web_Engagement_Count__c) 
        then
          0 
        else
          sub1.Web_Engagement_Count__c 
      end
) as Web_Engagement_Count__c 
    FROM
      (
        SELECT
          COUNT(ssot__WebsiteEngagement__dlm.ssot__EngagementChannelActionId__c) as Web_Engagement_Count__c,
          UnifiedIndividual__dlm.ssot__Id__c as Unified_Individual__c,
          Content_Catalog__dlm.category__c as Content_Category__c,
          ssot__GoodsProduct__dlm.Category__c as Product_Category__c,
          ssot__GoodsProduct__dlm.Subcategory__c as Product_SubCategory__c,
          ssot__GoodsProduct__dlm.Product_Name__c as Product_Name__c,
          ssot__GoodsProduct__dlm.ssot__BrandId__c as Brand__c 
        FROM
          UnifiedIndividual__dlm 
          INNER JOIN
            IndividualIdentityLink__dlm 
            ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c 
          FULL JOIN
            ssot__WebsiteEngagement__dlm 
            ON IndividualIdentityLink__dlm.SourceRecordId__c = ssot__WebsiteEngagement__dlm.ssot__IndividualId__c 
          LEFT Join
            ssot__GoodsProduct__dlm 
            on ssot__GoodsProduct__dlm.ssot__Id__c = ssot__WebsiteEngagement__dlm.SKU__c 
          LEFT JOIN
            Content_Catalog__dlm 
            ON Content_Catalog__dlm.contentid__c = ssot__WebsiteEngagement__dlm.Content_ID__c 
        GROUP BY
          UnifiedIndividual__dlm.ssot__Id__c,
          Content_Catalog__dlm.category__c,
          ssot__GoodsProduct__dlm.Category__c,
          ssot__GoodsProduct__dlm.Subcategory__c,
          ssot__GoodsProduct__dlm.Product_Name__c,
          ssot__GoodsProduct__dlm.ssot__BrandId__c 
      )
      as sub1 
    GROUP BY
      sub1.Unified_Individual__c,
      sub1.Content_Category__c,
      sub1.Product_Category__c,
      sub1.Product_SubCategory__c,
      sub1.Product_Name__c,
      sub1.Brand__c 
  )
  AS userScore 
  FULL JOIN
    (
      SELECT
        MAX(sub2.Web_Engagement_Count__c) as totalmaxwebengagementcount__c 
      FROM
        (
          SELECT
            sub1.Unified_Individual__c as Unified_Individual__c,
            sub1.Content_Category__c as Content_Category__c,
            sub1.Product_Category__c as Product_Category__c,
            sub1.Product_SubCategory__c as Product_SubCategory__c,
            sub1.Product_Name__c as Product_Name__c,
            sub1.Brand__c as Brand__c,
            SUM( 
            CASE
              when
                isnull(sub1.Web_Engagement_Count__c) 
              then
                0 
              else
                sub1.Web_Engagement_Count__c 
            end
) as Web_Engagement_Count__c 
          FROM
            (
              SELECT
                COUNT(ssot__WebsiteEngagement__dlm.ssot__EngagementChannelActionId__c) as Web_Engagement_Count__c,
                UnifiedIndividual__dlm.ssot__Id__c as Unified_Individual__c,
                Content_Catalog__dlm.category__c as Content_Category__c,
                ssot__GoodsProduct__dlm.Category__c as Product_Category__c,
                ssot__GoodsProduct__dlm.Subcategory__c as Product_SubCategory__c,
                ssot__GoodsProduct__dlm.Product_Name__c as Product_Name__c,
                ssot__GoodsProduct__dlm.ssot__BrandId__c as Brand__c 
              FROM
                UnifiedIndividual__dlm 
                INNER JOIN
                  IndividualIdentityLink__dlm 
                  ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c 
                FULL JOIN
                  ssot__WebsiteEngagement__dlm 
                  ON IndividualIdentityLink__dlm.SourceRecordId__c = ssot__WebsiteEngagement__dlm.ssot__IndividualId__c 
                LEFT Join
                  ssot__GoodsProduct__dlm 
                  on ssot__GoodsProduct__dlm.ssot__Id__c = ssot__WebsiteEngagement__dlm.SKU__c 
                LEFT JOIN
                  Content_Catalog__dlm 
                  ON Content_Catalog__dlm.contentid__c = ssot__WebsiteEngagement__dlm.Content_ID__c 
              GROUP BY
                UnifiedIndividual__dlm.ssot__Id__c,
                Content_Catalog__dlm.category__c,
                ssot__GoodsProduct__dlm.Category__c,
                ssot__GoodsProduct__dlm.Subcategory__c,
                ssot__GoodsProduct__dlm.Product_Name__c,
                ssot__GoodsProduct__dlm.ssot__BrandId__c 
            )
            as sub1 
          GROUP BY
            sub1.Unified_Individual__c,
            sub1.Content_Category__c,
            sub1.Product_Category__c,
            sub1.Product_SubCategory__c,
            sub1.Product_Name__c,
            sub1.Brand__c 
        )
        as sub2 
    )
    AS totalMax 
    ON userScore.Unified_Individual__c <> '' 
    AND totalMax.totalmaxwebengagementcount__c <> - 1000 
Group by
  Unified_Individual__c,
  Content_Category__c,
  Product_Category__c,
  Product_SubCategory__c,
  Product_Name__c,
  Brand__c
```

*Mobile Engagement Score*  
```
SELECT
  userScore.Unified_Individual__c as Unified_Individual__c,
  (
    FIRST(userScore.Mobile_Engagement_Count__c) / Max(totalMax.totalmaxmobileengagementcount__c) 
  )
  *100 as Mobile_Engagement_Score__c,
  userScore.Content_Category__c as Content_Category__c,
  userScore.Product_Category__c as Product_Category__c,
  userScore.Product_SubCategory__c as Product_SubCategory__c,
  userScore.Product_Name__c as Product_Name__c,
  userScore.Brand__c as Brand__c 
FROM
  (
    SELECT
      sub1.Unified_Individual__c as Unified_Individual__c,
      sub1.Content_Category__c as Content_Category__c,
      sub1.Product_Category__c as Product_Category__c,
      sub1.Product_SubCategory__c as Product_SubCategory__c,
      sub1.Product_Name__c as Product_Name__c,
      sub1.Brand__c as Brand__c,
      SUM( 
      CASE
        when
          isnull(sub1.Mobile_Engagement_Count__c) 
        then
          0 
        else
          sub1.Mobile_Engagement_Count__c 
      end
) as Mobile_Engagement_Count__c 
    FROM
      (
        SELECT
          COUNT(ssot__DeviceApplicationEngagement__dlm.ssot__EngagementChannelActionId__c) as Mobile_Engagement_Count__c,
          UnifiedIndividual__dlm.ssot__Id__c as Unified_Individual__c,
          Content_Catalog__dlm.category__c as Content_Category__c,
          ssot__GoodsProduct__dlm.Category__c as Product_Category__c,
          ssot__GoodsProduct__dlm.Subcategory__c as Product_SubCategory__c,
          ssot__GoodsProduct__dlm.Product_Name__c as Product_Name__c,
          ssot__GoodsProduct__dlm.ssot__BrandId__c as Brand__c 
        FROM
          UnifiedIndividual__dlm 
          INNER JOIN
            IndividualIdentityLink__dlm 
            ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c 
          FULL JOIN
            ssot__DeviceApplicationEngagement__dlm 
            ON IndividualIdentityLink__dlm.SourceRecordId__c = ssot__DeviceApplicationEngagement__dlm.ssot__IndividualId__c 
          LEFT Join
            ssot__GoodsProduct__dlm 
            on ssot__GoodsProduct__dlm.ssot__Id__c = ssot__DeviceApplicationEngagement__dlm.sku__c 
          LEFT JOIN
            Content_Catalog__dlm 
            ON Content_Catalog__dlm.contentid__c = ssot__DeviceApplicationEngagement__dlm.ContentID__c 
        GROUP BY
          UnifiedIndividual__dlm.ssot__Id__c,
          Content_Catalog__dlm.category__c,
          ssot__GoodsProduct__dlm.Category__c,
          ssot__GoodsProduct__dlm.Subcategory__c,
          ssot__GoodsProduct__dlm.Product_Name__c,
          ssot__GoodsProduct__dlm.ssot__BrandId__c 
      )
      as sub1 
    GROUP BY
      sub1.Unified_Individual__c,
      sub1.Content_Category__c,
      sub1.Product_Category__c,
      sub1.Product_SubCategory__c,
      sub1.Product_Name__c,
      sub1.Brand__c 
  )
  AS userScore 
  FULL JOIN
    (
      SELECT
        MAX(sub2.Mobile_Engagement_Count__c) as totalmaxmobileengagementcount__c 
      FROM
        (
          SELECT
            sub1.Unified_Individual__c as Unified_Individual__c,
            sub1.Content_Category__c as Content_Category__c,
            sub1.Product_Category__c as Product_Category__c,
            sub1.Product_SubCategory__c as Product_SubCategory__c,
            sub1.Product_Name__c as Product_Name__c,
            sub1.Brand__c as Brand__c,
            SUM( 
            CASE
              when
                isnull(sub1.Mobile_Engagement_Count__c) 
              then
                0 
              else
                sub1.Mobile_Engagement_Count__c 
            end
) as Mobile_Engagement_Count__c 
          FROM
            (
              SELECT
                COUNT(ssot__DeviceApplicationEngagement__dlm.ssot__EngagementChannelActionId__c) as Mobile_Engagement_Count__c,
                UnifiedIndividual__dlm.ssot__Id__c as Unified_Individual__c,
                Content_Catalog__dlm.category__c as Content_Category__c,
                ssot__GoodsProduct__dlm.Category__c as Product_Category__c,
                ssot__GoodsProduct__dlm.Subcategory__c as Product_SubCategory__c,
                ssot__GoodsProduct__dlm.Product_Name__c as Product_Name__c,
                ssot__GoodsProduct__dlm.ssot__BrandId__c as Brand__c 
              FROM
                UnifiedIndividual__dlm 
                INNER JOIN
                  IndividualIdentityLink__dlm 
                  ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c 
                FULL JOIN
                  ssot__DeviceApplicationEngagement__dlm 
                  ON IndividualIdentityLink__dlm.SourceRecordId__c = ssot__DeviceApplicationEngagement__dlm.ssot__IndividualId__c 
                LEFT Join
                  ssot__GoodsProduct__dlm 
                  on ssot__GoodsProduct__dlm.ssot__Id__c = ssot__DeviceApplicationEngagement__dlm.sku__c 
                LEFT JOIN
                  Content_Catalog__dlm 
                  ON Content_Catalog__dlm.contentid__c = ssot__DeviceApplicationEngagement__dlm.ContentID__c 
              GROUP BY
                UnifiedIndividual__dlm.ssot__Id__c,
                Content_Catalog__dlm.category__c,
                ssot__GoodsProduct__dlm.Category__c,
                ssot__GoodsProduct__dlm.Subcategory__c,
                ssot__GoodsProduct__dlm.Product_Name__c,
                ssot__GoodsProduct__dlm.ssot__BrandId__c 
            )
            as sub1 
          GROUP BY
            sub1.Unified_Individual__c,
            sub1.Content_Category__c,
            sub1.Product_Category__c,
            sub1.Product_SubCategory__c,
            sub1.Product_Name__c,
            sub1.Brand__c 
        )
        as sub2 
    )
    AS totalMax 
    ON userScore.Unified_Individual__c <> '' 
    AND totalMax.totalmaxmobileengagementcount__c <> - 1000 
Group by
  Unified_Individual__c,
  Content_Category__c,
  Product_Category__c,
  Product_SubCategory__c,
  Product_Name__c,
  Brand__c
```

*Email Engagement Score*  
```
 Select
  userScore.Unified_Individual__c as Unified_Individual__c,
  (
    FIRST(userScore.Email_Engagement_Count__c) / Max(totalMax.totalmaxemailengagementcount__c ) 
  )
  *100 as Email_Engagement_Score__c 
FROM
  (
    SELECT
      sub2.Unified_Individual__c as Unified_Individual__c,
      SUM( 
      CASE
        when
          isnull(sub2.Email_Engagement_Count__c) 
        then
          0 
        else
          sub2.Email_Engagement_Count__c 
      end
) as Email_Engagement_Count__c 
    FROM
      (
        SELECT
          SUM(sub1.EmailOpenCount__c + sub1.EmailClickCount__c) as Email_Engagement_Count__c,
          sub1.Unified_Individual__c AS Unified_Individual__c 
        FROM
          (
            SELECT
              SUM( 
              CASE
                WHEN
                  ssot__EmailEngagement__dlm.ssot__EngagementChannelActionId__c = 'Open' 
                THEN
                  1 
                ELSE
                  0 
              end
) AS EmailOpenCount__c, SUM( 
              CASE
                WHEN
                  ssot__EmailEngagement__dlm.ssot__EngagementChannelActionId__c = 'Click' 
                THEN
                  1 
                ELSE
                  0 
              end
) AS EmailClickCount__c, UnifiedIndividual__dlm.ssot__Id__c as Unified_Individual__c 
            FROM
              UnifiedIndividual__dlm 
              INNER JOIN
                IndividualIdentityLink__dlm 
                ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c 
              FULL JOIN
                ssot__EmailEngagement__dlm 
                ON IndividualIdentityLink__dlm.SourceRecordId__c = ssot__EmailEngagement__dlm.ssot__IndividualId__c 
            GROUP BY
              UnifiedIndividual__dlm.ssot__Id__c 
          )
          as sub1 
        GROUP BY
          sub1.Unified_Individual__c 
      )
      as sub2 
    GROUP BY
      sub2.Unified_Individual__c 
  )
  AS userScore 
  FULL JOIN
    (
      SELECT
        MAX(sub3.Email_Engagement_Count__c) as totalmaxemailengagementcount__c 
      FROM
        (
          SELECT
            sub2.Unified_Individual__c as Unified_Individual__c,
            SUM( 
            CASE
              when
                isnull(sub2.Email_Engagement_Count__c) 
              then
                0 
              else
                sub2.Email_Engagement_Count__c 
            end
) as Email_Engagement_Count__c 
          FROM
            (
              SELECT
                SUM(sub1.EmailOpenCount__c + sub1.EmailClickCount__c) as Email_Engagement_Count__c,
                sub1.Unified_Individual__c AS Unified_Individual__c 
              FROM
                (
                  SELECT
                    SUM( 
                    CASE
                      WHEN
                        ssot__EmailEngagement__dlm.ssot__EngagementChannelActionId__c = 'Open' 
                      THEN
                        1 
                      ELSE
                        0 
                    end
) AS EmailOpenCount__c, SUM( 
                    CASE
                      WHEN
                        ssot__EmailEngagement__dlm.ssot__EngagementChannelActionId__c = 'Click' 
                      THEN
                        1 
                      ELSE
                        0 
                    end
) AS EmailClickCount__c, UnifiedIndividual__dlm.ssot__Id__c as Unified_Individual__c 
                  FROM
                    UnifiedIndividual__dlm 
                    INNER JOIN
                      IndividualIdentityLink__dlm 
                      ON UnifiedIndividual__dlm.ssot__Id__c = IndividualIdentityLink__dlm.UnifiedRecordId__c 
                    FULL JOIN
                      ssot__EmailEngagement__dlm 
                      ON IndividualIdentityLink__dlm.SourceRecordId__c = ssot__EmailEngagement__dlm.ssot__IndividualId__c 
                  GROUP BY
                    UnifiedIndividual__dlm.ssot__Id__c 
                )
                as sub1 
              GROUP BY
                sub1.Unified_Individual__c 
            )
            as sub2 
          GROUP BY
            sub2.Unified_Individual__c 
        )
        as sub3 
    )
    AS totalMax 
    ON userScore.Unified_Individual__c <> '' 
    AND totalMax.totalmaxemailengagementcount__c <> - 1000 
Group by
  Unified_Individual__c
```

**Beyond People Product Clusters_Analytics - Calculated Insight Query**

*Creates dimensions for each combination of Recency, Frequency, and Monetary (RFM) and their corresponding product cluster names as well as product related dimensions such as Product SKU and Product Category. Creates measures R, F, and M for Purchase and Engagement data separately that are averaged together to get the R, F, and M values and then divided by the max score for all Product SKUs to get the R, F, and M Scores. Important note: Unlike many of the other queries in this repository, the Beyond People query here is grouped by Product_SKU instead of Unified Individual.*

*This query corresponds to the data schema in the attached PDF  

| Measure                | Dimensions            |
| -----------            | -----------           |
| Recency_Score__c       | RF_Product_Cluster__c |
| Frequency_Score__c     | FM_Product_Cluster__c |
| Monetary_Score__c      | RM_Product_Cluster__c |
| Recency__c             | Product_SKU__c        |
| Frequency__c           | Product_Name__c       |
| Monetary__c            | Product_Category__c   |
| Purchase_Recency__c    | Product_Subcategory__c|
| Purchase_Frequency__c  | Brand__c              |
| Purchase_Monetary__c   |                       |
| Engagement_Recency__c  |                       |
| Engagement_Frequency__c|                       |
| Engagement_Monetary__c |                       |

```
Query is located in the attached file
```

