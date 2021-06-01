# Salesforce CDP Calculated Insights

The Calculated Insights feature lets you define and calculate multidimensional metrics from your entire digital state stored in Salesforce CDP

Your metrics can include customer lifetime value (LTV), Most Viewed Categories, and customer satisfaction score (CSAT), Affinity Scores at the profile, segment, population level, or any other desired specialized metrics. Marketers can use Calculated Insights to define segment criteria and personalization attributes for activation using metrics, dimensions, and filters. 

This project containes example of creating Calculated Insights in Salesforce CDP

Example # Calculate spend by the customer. Creates a measure customer_spend__c and a dimension custid__c

| Measure            | Dimension   |
| -----------        | ----------- |
| customer_spend__c  | custid__c   |

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




