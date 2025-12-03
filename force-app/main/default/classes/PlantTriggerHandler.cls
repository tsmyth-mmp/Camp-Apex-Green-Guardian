public with sharing class PlantTriggerHandler implements ITriggerHandler {
    private PlantTriggerHelper helper;
    
    public PlantTriggerHandler() {
        helper = new PlantTriggerHelper();
    }

    public void beforeInsert(List<SObject> newRecords) {
        List<CAMPX__Plant__c> plants = (List<CAMPX__Plant__c>) newRecords;
        helper.processBeforeInsert(plants);
    }

    public void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<Id, SObject> oldRecordMap, Map<Id, SObject> newRecordMap) {
        List<CAMPX__Plant__c> oldPlants = (List<CAMPX__Plant__c>) oldRecords;
        List<CAMPX__Plant__c> newPlants = (List<CAMPX__Plant__c>) newRecords;
        Map<Id, CAMPX__Plant__c> oldMap = (Map<Id, CAMPX__Plant__c>) oldRecordMap;
        Map<Id, CAMPX__Plant__c> newMap = (Map<Id, CAMPX__Plant__c>) newRecordMap;
        // helper.processBeforeUpdate(oldPlants, newPlants);
    }

    public void beforeDelete(List<SObject> oldRecords, Map<Id, SObject> oldRecordMap) {
        List<CAMPX__Plant__c> oldPlants = (List<CAMPX__Plant__c>) oldRecords;
        Map<Id, CAMPX__Plant__c> oldMap = (Map<Id, CAMPX__Plant__c>) oldRecordMap;
        // helper.processBeforeDelete(oldPlants, oldMap);
    }

    public void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {
        List<CAMPX__Plant__c> plants = (List<CAMPX__Plant__c>) newRecords;
        Map<Id, CAMPX__Plant__c> newPlantsMap = (Map<Id, CAMPX__Plant__c>) newRecordMap;
        // helper.processAfterInsert(plants, newPlantsMap);
    }
    
    public void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<Id, SObject> oldRecordMap, Map<Id, SObject> newRecordMap) {
        List<CAMPX__Plant__c> oldPlants = (List<CAMPX__Plant__c>) oldRecords;
        List<CAMPX__Plant__c> newPlants = (List<CAMPX__Plant__c>) newRecords;
        Map<Id, CAMPX__Plant__c> oldMap = (Map<Id, CAMPX__Plant__c>) oldRecordMap;
        Map<Id, CAMPX__Plant__c> newMap = (Map<Id, CAMPX__Plant__c>) newRecordMap;
        // helper.processAfterUpdate(oldPlants, newPlants, oldMap, newMap);
    }
}