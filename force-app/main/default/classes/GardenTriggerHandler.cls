public with sharing class GardenTriggerHandler implements ITriggerHandler {
    private GardenTriggerHelper helper;
    
    public GardenTriggerHandler() {
        helper = new GardenTriggerHelper();
    }

    public void beforeInsert(List<SObject> newRecords) {
        List<CAMPX__Garden__c> gardens = (List<CAMPX__Garden__c>) newRecords;
        helper.processBeforeInsert(gardens);
    }


}