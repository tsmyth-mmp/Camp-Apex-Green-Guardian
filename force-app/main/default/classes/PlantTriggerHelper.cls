public with sharing class PlantTriggerHelper {
    public void processBeforeInsert(List<CAMPX__Plant__c> plants) {
       Set<Id> gardenIds = getGardenIdSet(plants);
       Map<Id, CAMPX__Garden__c> gardenMap = new Map<Id, CAMPX__Garden__c>([SELECT Id, CAMPX__Sun_Exposure__c FROM CAMPX__Garden__c WHERE Id IN :gardenIds]);
       
       for (CAMPX__Plant__c plant : plants) {
        initializeFields(plant, gardenMap);
        }
    }

    private void initializeFields(CAMPX__Plant__c plant, Map<Id, CAMPX__Garden__c> gardenMap) {
        plant.CAMPX__Soil_Type__c = String.isNotBlank(plant.CAMPX__Soil_Type__c) ? plant.CAMPX__Soil_Type__c : 'All Purpose Potting Soil';
        plant.CAMPX__Water__c = plant.CAMPX__Water__c != null ? plant.CAMPX__Water__c : 'Once Weekly';
        plant.CAMPX__Sunlight__c = (plant.CAMPX__Garden__c != null && gardenMap.containsKey(plant.CAMPX__Garden__c)) ? gardenMap.get(plant.CAMPX__Garden__c).CAMPX__Sun_Exposure__c : 'Partial Sun';
    }

    private Set<Id> getGardenIdSet(List<CAMPX__Plant__c> plants) {
        Set<Id> gardenIds = new Set<Id>();
        for (CAMPX__Plant__c plant : plants) {
            if (plant.CAMPX__Garden__c != null) {
                gardenIds.add(plant.CAMPX__Garden__c);
            }
        }
        return gardenIds;
    }
}