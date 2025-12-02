trigger GardenTrigger on CAMPX__Garden__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    GardenTriggerHandler handler = new GardenTriggerHandler();

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.beforeInsert(Trigger.new);
        }
    }
}