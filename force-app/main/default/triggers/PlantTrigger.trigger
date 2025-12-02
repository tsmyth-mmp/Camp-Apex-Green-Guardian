trigger PlantTrigger on CAMPX__Plant__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    PlantTriggerHandler handler = new PlantTriggerHandler();

    switch on Trigger.operationType {
        when BEFORE_INSERT {
            handler.beforeInsert(Trigger.new);
        }
    }
}