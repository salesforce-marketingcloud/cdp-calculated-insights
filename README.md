# Salesforce CDP: Calculated Insights Examples

Salesforce CDP Calculated Insights Help (https://help.salesforce.com/articleView?id=sf.c360_a_calculated_insights.htm&type=5)

The Calculated Insights feature lets you define and calculate multidimensional metrics from your entire digital state stored in Salesforce CDP

Your metrics can include customer lifetime value (LTV), Most Viewed Categories, and customer satisfaction score (CSAT), Affinity Scores at the profile, segment, population level, or any other desired specialized metrics. Marketers can use Calculated Insights to define segment criteria and personalization attributes for activation using metrics, dimensions, and filters. 

This project containes examples of creating Calculated Insights in Salesforce CDP

**Example: Calculate spend by the customer. Creates a measure customer_spend__c and a dimension custid__c**

```
SELECT
    SUM( SALESORDER__dlm.grand_total_amount__c ) as customer_spend__c,
    Individual__dlm.Id__c as custid__c
FROM
    SALESORDER__dlm
JOIN
    Individual__dlm
ON
    SALESORDER__dlm.partyid__c= Individual__dlm.Id__c 
GROUP BY
custid__c
```
| Measure            | Dimension   |
| -----------        | ----------- |
| customer_spend__c  | custid__c   |


**Example: Calculate spend by the customer and product. Creates a measure customer_spend__c and two dimensions custid__c and product__c**
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

**Example: UnifiedIndividalID as a dimension, Calculate Count of email Opened for each Unified Individual**

```
SELECT  COUNT( EmailEngagement__dlm.Id__c) as email_open_count__c,
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

**Example: Recency Frequency and Monetary metrics** 

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
        cust_id__c 
        ) as sub2 
GROUP BY 
sub2.cust_id__c

```

| Measure              | Dimension      |
| -----------          | -----------    |
| Recency__c           | cust_id__c     |
| Frequency__c         |                |
| Monetary__c          |                |
| rfm_combined__c      |                |


**Example: Email Open Rates and Click Rates by Unified Individual** 

```
SELECT 
    SUM(NestedQuery.EmailOpen__c)/SUM(NestedQuery.EmailSend__c)*100 as Open_Rate__c,
    SUM(NestedQuery.EmailClick__c)/SUM(NestedQuery.EmailSend__c)*100 as Click_Rate__c,
    NestedQuery.customer_id__c as id__c
    FROM
        (
            SELECT COUNT (CASE WHEN EmailEngagement__dlm.EngagementChannelActionId__c = 'Open' THEN 1 ELSE 0 end) as EmailOpen__c,
            COUNT (CASE WHEN EmailEngagement__dlm.EngagementChannelActionId__c = 'Click' THEN 1 ELSE 0 end) as EmailClick__c,
            COUNT (CASE WHEN EmailEngagement__dlm.EngagementChannelActionId__c = 'Send' THEN 1 ELSE 0 end) as EmailSend__c,
            UnifiedIndividual__dlm.Id__c as customer_id__c
        FROM
            EmailEngagement__dlm
            LEFT JOIN
            IndividualIdentityLink__dlm
            ON
            EmailEngagement__dlm.IndividualId__c=IndividualIdentityLink__dlm.SourceRecordId__c
            LEFT Join
            UnifiedIndividual__dlm
            ON
            UnifiedIndividual__dlm.Id__c=IndividualIdentityLink__dlm.UnifiedRecordId__c
        GROUP BY
        customer_id__c
        ) as NestedQuery
    Group BY 
    id__c
```
| Measure              | Dimension      |
| -----------          | -----------    |
| Open_Rate__c         | id__c          |
| Click_Rate__c        |                |

**Example: Bucket customers (High Medium, low spenders) based on spend and by product** 
```
SELECT
    CASE
        WHEN    
            SUM( SALESORDER__dlm.grand_total_amount__c ) < 100 THEN 'Low Spender'
        WHEN
            SUM( SALESORDER__dlm.grand_total_amount__c ) >100 AND  SUM( SALESORDER__dlm.grand_total_amount__c )<=500  THEN 'Medium Spender' 
        WHEN 
            SUM( SALESORDER__dlm.grand_total_amount__c ) >500 then 'High Spender' end as spend_bucket__c,
            SUM(SALESORDER__dlm.grand_total_amount__c ) as spend__c,
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
    LEFT JOIN
        Individual__dlm
    ON
        SALESORDER__dlm.partyid__c= Individual__dlm.Id__c 
GROUP BY
        custid__c, 
        product__c
```
| Measure              | Dimension      |
| -----------          | -----------    |
| spend_bucket__c      | custid__c      |
| spend__c             | product__c     |

**Example: Find Product category buying affinity for the each customer** 
```
SELECT
    FIRST(SubQuery2.highest_purcahased_rank__c) as Affinity__c,
    SubQuery2.CustomerId__c as Customer_Id__c,
    SubQuery2.product__c as Category__c
        FROM
            (
            SELECT
            RANK() OVER ( PARTITION BY SubQuery1.individual_id__c
            order by (SubQuery1.product_purchase_count__c) desc )
            as highest_purcahased_rank__c,
            SubQuery1.individual_id__c as CustomerId__c,
            SubQuery1.product_cat__c as product__c
            FROM
                (
                SELECT
                   Individual__dlm.Id__c   as individual_id__c,
                   PRODUCT__dlm.product_category__c   as product_cat__c,
                   COUNT( PRODUCT__dlm.product_sk_u__c ) as product_purchase_count__c
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
                        group by
                        individual_id__c, product_cat__c
                ) as SubQuery1
          ) as SubQuery2
GROUP BY
Customer_Id__c, 
Category__c
```

| Measure              | Dimension      |
| -----------          | -----------    |
| Affinity__c          | Customer_Id__c |
|                      | Category__c    |