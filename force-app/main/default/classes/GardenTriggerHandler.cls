public with sharing class GardenTriggerHandler implements ITriggerHandler {
    private GardenTriggerHelper helper;
    
    public GardenTriggerHandler() {
        helper = new GardenTriggerHelper();
    }

    public void beforeInsert(List<SObject> newRecords) {
        List<CAMPX__Garden__c> gardens = (List<CAMPX__Garden__c>) newRecords;
        helper.processBeforeInsert(gardens);
    }

    public void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {
        List<CAMPX__Garden__c> gardens = (List<CAMPX__Garden__c>) newRecords;
        Map<Id, CAMPX__Garden__c> newGardenMap = (Map<Id, CAMPX__Garden__c>) newRecordMap;
        helper.processAfterInsert(gardens, newGardenMap);
    }


}