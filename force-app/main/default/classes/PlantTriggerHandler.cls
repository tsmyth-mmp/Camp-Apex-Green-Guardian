public with sharing class PlantTriggerHandler implements ITriggerHandler {
    private PlantTriggerHelper helper;
    
    public PlantTriggerHandler() {
        helper = new PlantTriggerHelper();
    }

    public void beforeInsert(List<SObject> newRecords) {
        List<CAMPX__Plant__c> plants = (List<CAMPX__Plant__c>) newRecords;
        helper.processBeforeInsert(plants);
    }

    public void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordMap) {

    }
}