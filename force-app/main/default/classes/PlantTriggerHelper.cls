public with sharing class PlantTriggerHelper {
    public void processBeforeInsert(List<CAMPX__Plant__c> plants) {
        Set<Id> gardenIds = createGardenIdSet(plants);
        Map<Id, CAMPX__Garden__c> gardenMap = new Map<Id, CAMPX__Garden__c>([SELECT Id, CAMPX__Sun_Exposure__c FROM CAMPX__Garden__c WHERE Id IN :gardenIds]);
        
        for (CAMPX__Plant__c plant : plants) {
            initializeFields(plant, gardenMap);
        }
    }

    public void processBeforeUpdate(List<CAMPX__Plant__c> oldRecords, List<CAMPX__Plant__c> newRecords, Map<Id, CAMPX__Plant__c> oldMap, Map<Id, CAMPX__Plant__c> newMap) {
        
    }

    public void processAfterInsert(List<CAMPX__Plant__c> plants, Map<Id, CAMPX__Plant__c> newMap) {
        updateGardenTotalPlantCount(plants);
    }

    public void processAfterUpdate(List<CAMPX__Plant__c> oldRecords, List<CAMPX__Plant__c> newRecords, Map<Id, CAMPX__Plant__c> oldMap, Map<Id, CAMPX__Plant__c> newMap) {
        
    }

    private void initializeFields(CAMPX__Plant__c plant, Map<Id, CAMPX__Garden__c> gardenMap) {
        plant.CAMPX__Soil_Type__c = String.isNotBlank(plant.CAMPX__Soil_Type__c) ? plant.CAMPX__Soil_Type__c : 'All Purpose Potting Soil';
        plant.CAMPX__Water__c = plant.CAMPX__Water__c != null ? plant.CAMPX__Water__c : 'Once Weekly';
        plant.CAMPX__Sunlight__c = (plant.CAMPX__Garden__c != null && gardenMap.containsKey(plant.CAMPX__Garden__c)) ? gardenMap.get(plant.CAMPX__Garden__c).CAMPX__Sun_Exposure__c : 'Partial Sun';
    }

    private Set<Id> createGardenIdSet(List<CAMPX__Plant__c> plants) {
        Set<Id> gardenIds = new Set<Id>();
        for (CAMPX__Plant__c plant : plants) {
            if (plant.CAMPX__Garden__c != null) {
                gardenIds.add(plant.CAMPX__Garden__c);
            }
        }
        return gardenIds;
    }
}