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