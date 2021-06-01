SUM(Order_Line__dlm.ref_quantity__c)/APPROX_COUNT_DISTINCT(Order_Header__dlm.order_number__c ) as Whole_Pie_Count_Avg__c, UnifiedIndividual__dlm.ssot__Id__c as CustomerId__c FROM Order_Header__dlm LEFT JOIN IndividualIdentityLink__dlm ON IndividualIdentityLink__dlm.SourceRecordId__c = Order_Header__dlm.customer_master_number__c LEFT JOIN UnifiedIndividual__dlm on UnifiedIndividual__dlm.ssot__Id__c =IndividualIdentityLink__dlm.UnifiedRecordId__c INNER JOIN Order_Line__dlm ON Order_Header__dlm.order_number__c = Order_Line__dlm.order_number__c LEFT JOIN PRODUCT_CATALOG_ECOM__dlm ON Order_Line__dlm.product_code__c = PRODUCT_CATALOG_ECOM__dlm.productcode__c WHERE Order_Header__dlm.last_270d_status_flag__c = 1 AND PRODUCT_CATALOG_ECOM__dlm.producttype__c = 'PIZZA' GROUP BY UnifiedIndividual__dlm.ssot__Id__c