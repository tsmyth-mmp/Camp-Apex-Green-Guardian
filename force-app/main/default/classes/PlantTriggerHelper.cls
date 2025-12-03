public with sharing class PlantTriggerHelper {
    public void processBeforeInsert(List<CAMPX__Plant__c> newRecords) {
        initializePlants(newRecords);   
    }

    public void processBeforeUpdate(
        List<CAMPX__Plant__c> oldRecords, 
        List<CAMPX__Plant__c> newRecords, 
        Map<Id, CAMPX__Plant__c> oldMap, 
        Map<Id, CAMPX__Plant__c> newMap 
    ) {
        
    }

    public void processAfterInsert(List<CAMPX__Plant__c> newRecords, Map<Id, CAMPX__Plant__c> newMap) {
        updateGardenTotalPlantCount(null, newRecords);
    }

    public void processAfterUpdate(
        List<CAMPX__Plant__c> oldRecords,
        List<CAMPX__Plant__c> newRecords,
        Map<Id, CAMPX__Plant__c> oldMap,
        Map<Id, CAMPX__Plant__c> newMap
         
    ) {
        updateGardenTotalPlantCount(oldRecords, newRecords);
    }

    public void processAfterDelete(List<CAMPX__Plant__c> oldRecords, Map<Id, CAMPX__Plant__c> oldMap) {
        updateGardenTotalPlantCount(oldRecords, null);
    }

    private void initializeFields(CAMPX__Plant__c plant, Map<Id, CAMPX__Garden__c> gardenMap) {
        plant.CAMPX__Soil_Type__c = String.isNotBlank(plant.CAMPX__Soil_Type__c) ? plant.CAMPX__Soil_Type__c : 'All Purpose Potting Soil';
        plant.CAMPX__Water__c = plant.CAMPX__Water__c != null ? plant.CAMPX__Water__c : 'Once Weekly';
        plant.CAMPX__Sunlight__c = (plant.CAMPX__Garden__c != null && gardenMap.containsKey(plant.CAMPX__Garden__c)) ? gardenMap.get(plant.CAMPX__Garden__c).CAMPX__Sun_Exposure__c : 'Partial Sun';
    }

    private Set<Id> createGardenIdSet(List<CAMPX__Plant__c> plants) {
        Set<Id> gardenIds = new Set<Id>();
        if (plants != null) {
            for (CAMPX__Plant__c plant : plants) {
                if (plant.CAMPX__Garden__c != null) {
                    gardenIds.add(plant.CAMPX__Garden__c);
                }
            }
        }
        return gardenIds;
    }

    private void initializePlants(List<CAMPX__Plant__c> plants) {
        Set<Id> gardenIds = createGardenIdSet(plants);
        if (gardenIds.isEmpty()) return;
        Map<Id, CAMPX__Garden__c> gardenMap = new Map<Id, CAMPX__Garden__c>([SELECT Id, CAMPX__Sun_Exposure__c FROM CAMPX__Garden__c WHERE Id IN :gardenIds]);
        for (CAMPX__Plant__c plant : plants) {
            initializeFields(plant, gardenMap);
        }
    }

    private Set<Id> getAffectedGardenIds(List<CAMPX__Plant__c> oldPlants, List<CAMPX__Plant__c> newPlants) {
        Set<Id> gardenIds = new Set<Id>();

        if (oldPlants != null && newPlants != null) {
            for (Integer i = 0; i < oldPlants.size(); i++) {
                Id oldId = oldPlants[i].CAMPX__Garden__c;
                Id newId = newPlants[i].CAMPX__Garden__c;

                if (oldId != newId) {
                    if (oldId != null) gardenIds.add(oldId);
                    if (newId != null) gardenIds.add(newId);
                } 
            }
        } else if (oldPlants != null) {
            gardenIds.addAll(createGardenIdSet(oldPlants));

        } else if (newPlants != null) {
            gardenIds.addAll(createGardenIdSet(newPlants));
        }

        return gardenIds;
    }

    private void updateGardenTotalPlantCount(List<CAMPX__Plant__c> oldPlants, List<CAMPX__Plant__c> newPlants) {
       Set<Id> affectedGardenIds = getAffectedGardenIds(oldPlants, newPlants);

        if (affectedGardenIds.isEmpty()) return;

        Map<Id, Integer> gardensTotalPlantCountMap = new Map<Id, Integer>(); 
        for (AggregateResult ar : [SELECT CAMPX__Garden__c gardenId, Count(Id) total
                                   FROM CAMPX__Plant__c 
                                   WHERE CAMPX__Garden__c IN :affectedGardenIds 
                                   GROUP BY CAMPX__Garden__c]
            ) 
        {
            gardensTotalPlantCountMap.put((Id)ar.get('gardenId'), (Integer)ar.get('total'));
        }

        List<CAMPX__Garden__c> gardensToUpdate = new List<CAMPX__Garden__c>();
        for (Id gardenId : affectedGardenIds) {
            Integer total = gardensTotalPlantCountMap.containsKey(gardenId) ? gardensTotalPlantCountMap.get(gardenId) : 0;
            gardensToUpdate.add(new CAMPX__Garden__c(Id = gardenId,CAMPX__Total_Plant_Count__c = total));
        }

        if (!gardensToUpdate.isEmpty()) {
            update gardensToUpdate;
        }
    }
}