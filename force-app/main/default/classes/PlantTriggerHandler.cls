public with sharing class PlantTriggerHandler {
    private PlantTriggerHelper helper;
    
    public PlantTriggerHandler() {
        helper = new PlantTriggerHelper();
    }

    public void beforeInsert(List<SObject> newRecords) {
        List<CAMPX__Plant__c> plants = (List<CAMPX__Plant__c>) newRecords;
        helper.processBeforeInsert(plants);
    }
}