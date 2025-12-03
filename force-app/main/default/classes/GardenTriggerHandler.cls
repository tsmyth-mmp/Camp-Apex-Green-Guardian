public with sharing class GardenTriggerHandler implements ITriggerHandler {
    private GardenTriggerHelper helper;
    
    public GardenTriggerHandler() {
        helper = new GardenTriggerHelper();
    }

    public void beforeInsert(List<SObject> newRecords) {
        List<CAMPX__Garden__c> gardens = (List<CAMPX__Garden__c>) newRecords;
        helper.processBeforeInsert(gardens);
    }

    public void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        List<CAMPX__Garden__c> oldGardens = (List<CAMPX__Garden__c>) oldRecords;
        List<CAMPX__Garden__c> newGardens = (List<CAMPX__Garden__c>) newRecords;
        Map<Id, CAMPX__Garden__c> oldGardenMap = (Map<Id, CAMPX__Garden__c>) oldMap;
        Map<Id, CAMPX__Garden__c> newGardenMap = (Map<Id, CAMPX__Garden__c>) newMap;
        helper.processBeforeUpdate(oldRecords, newGardens ,oldGardenMap, newGardenMap);
    }

    public void beforeDelete(List<SObject> oldRecords, Map<Id, SObject> oldMap) {
        List<CAMPX__Garden__c> oldGardens = (List<CAMPX__Garden__c>) oldRecords;
        Map<Id, CAMPX__Garden__c> oldGardenMap = (Map<Id, CAMPX__Garden__c>) oldMap;
        helper.processBeforeDelete(oldGardens, oldGardenMap);
    }

    public void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {
        List<CAMPX__Garden__c> gardens = (List<CAMPX__Garden__c>) newRecords;
        Map<Id, CAMPX__Garden__c> newGardenMap = (Map<Id, CAMPX__Garden__c>) newRecordMap;
        helper.processAfterInsert(gardens, newGardenMap);
    }


}