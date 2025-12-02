trigger GardenTrigger on CAMPX__Garden__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    GardenTriggerHandler handler = new GardenTriggerHandler();

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.beforeInsert(Trigger.new);
        }
        when BEFORE_UPDATE {
            handler.beforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        }
        when AFTER_INSERT {
            handler.afterInsert(Trigger.new, Trigger.newMap);
        }
    }
}