public class OrderConsolidateController {

    @AuraEnabled(cacheable=true)
    public static List<OrderItemProductWarrantyWrapper> getWrapperClassList(String orderId) {
        
        // Querring Order Items of Order by OrderId received from UI
        List<OrderItem> orderItems = [SELECT Id, OrderId, OrderItemNumber, PricebookEntry.Product2.Name,
                                            PricebookEntry.Product2Id, Product2Id, Order.BillToContactId, Quantity, UnitPrice 
                                    FROM OrderItem 
                                    WHERE OrderId =:  orderId];
        System.debug('orderItems: ' + orderItems);

        List<Id> productIds = new List<Id>();
        List<Id> contactsIds = new List<Id>();

        for(OrderItem item : orderItems) {
            contactsIds.add(item.Order.BillToContactId);
            productIds.add(item.Product2Id);   
        }

        List<Product_Warranty__c> productWarranties = [SELECT Id, Name, Contact__c, Product__c, Warranty_End_Date__c, Is_Active__c, Note__c
                                                        FROM Product_Warranty__c 
                                                        WHERE Contact__c IN : contactsIds 
                                                        AND Product__c IN : productIds];
        System.debug('productWarranties: ' + productWarranties);

        Map<String, Product_Warranty__c> productWarrantyByKey = new Map<String, Product_Warranty__c>();


        //sorting Product Warranty records by key contained from Contact and Product
        for(Product_Warranty__c productWarranty : productWarranties){

            String productWarrantyKey = (String)productWarranty.Contact__c + (String)productWarranty.Product__c;
            productWarrantyByKey.put(productWarrantyKey, productWarranty);
            
        }                      
        
        // Creating a list of OrderItemProductWarrantyWrappers for combined records
        List<OrderItemProductWarrantyWrapper> orderItemProdWarrantyWrappers = new List<OrderItemProductWarrantyWrapper>();

        // Loop for populating our list 
        for(OrderItem item: orderItems){

            OrderItemProductWarrantyWrapper ow = new OrderItemProductWarrantyWrapper(item, productWarrantyByKey);
        
            orderItemProdWarrantyWrappers.add(ow);
        }
        // add  error handiling here
        System.debug('orderItemProdWarrantyWrappers: ' + orderItemProdWarrantyWrappers);
        return orderItemProdWarrantyWrappers;
    }
    
    // Wrappper class for combined data
    public class OrderItemProductWarrantyWrapper {
        @AuraEnabled public String orderItemId;
        @AuraEnabled public String orderItemName;
        @AuraEnabled public Boolean isActive;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Double unitPrice;
        @AuraEnabled public Date warrantyEndDate;
        @AuraEnabled public String note;

        public OrderItemProductWarrantyWrapper(OrderItem item, Map<String, Product_Warranty__c> productWarrantyByKey){

            // Populating wrapper with item data
            this.orderItemId = item.Id;
            this.orderItemName = item.PricebookEntry.Product2.Name;
            this.quantity = item.Quantity;
            this.unitPrice = item.UnitPrice;

            // Populating Wrapper with consolidated data from Product Warranty by mapping with a key
            String oderItemKey = (String)item.Order.BillToContactId + (String)item.Product2Id;
            Product_Warranty__c currentProdWarranty = productWarrantyByKey.get(oderItemKey);

            if(currentProdWarranty != null) {
                this.warrantyEndDate = currentProdWarranty.Warranty_End_Date__c;
                this.note = currentProdWarranty.Note__c;
                this.isActive = currentProdWarranty.Is_Active__c;
            }
            
        } 
    }
}
