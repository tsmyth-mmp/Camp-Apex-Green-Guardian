public with sharing class PlantTriggerHandler implements ITriggerHandler {
    private PlantTriggerHelper helper;
    
    public PlantTriggerHandler() {
        helper = new PlantTriggerHelper();
    }

    public void beforeInsert(List<SObject> newRecords) {
        List<CAMPX__Plant__c> plants = (List<CAMPX__Plant__c>) newRecords;
        helper.processBeforeInsert(plants);
    }

       // before update
    public void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<Id, SObject> oldRecordMap, Map<Id, SObject> newRecordMap) {
        List<CAMPX__Plant__c> oldPlants = (List<CAMPX__Plant__c>) oldRecords;
        List<CAMPX__Plant__c> newPlants = (List<CAMPX__Plant__c>) newRecords;
        Map<Id, CAMPX__Plant__c> oldMap = (Map<Id, CAMPX__Plant__c>) oldRecordMap;
        Map<Id, CAMPX__Plant__c> newMap = (Map<Id, CAMPX__Plant__c>) newRecordMap;
        // helper.processBeforeUpdate(oldPlants, newPlants);
    }

    public void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {

    }
}