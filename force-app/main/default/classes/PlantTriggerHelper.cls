public with sharing class PlantTriggerHelper {
    private static final String STATUS_SICK = 'Sick';
    private static final String STATUS_WILITING = 'Wilting';
    private static final String STATUS_DECEASED = 'Deceased';

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

    /**
     * Initializes default field values on a CAMPX__Plant__c record.
     *
     * This method ensures that key plant attributes—Soil Type, Watering Frequency, 
     * and Sunlight Requirements—are populated with either user-provided values or 
     * sensible defaults. If the plant is associated with a garden, the garden's 
     * Sun Exposure setting is applied as the default sunlight value.
     *
     * Defaults:
     *   - Soil Type: "All Purpose Potting Soil"
     *   - Water: "Once Weekly"
     *   - Sunlight: Garden's Sun Exposure, or "Partial Sun" if no garden is found
     *
     * @param plant      The plant record being initialized.
     * @param gardenMap  A map of related garden records keyed by Id, used to fetch sun exposure values.
     */
    private void initializeFields(CAMPX__Plant__c plant, Map<Id, CAMPX__Garden__c> gardenMap) {
        plant.CAMPX__Soil_Type__c = String.isNotBlank(plant.CAMPX__Soil_Type__c) ? plant.CAMPX__Soil_Type__c : 'All Purpose Potting Soil';
        plant.CAMPX__Water__c = plant.CAMPX__Water__c != null ? plant.CAMPX__Water__c : 'Once Weekly';
        plant.CAMPX__Sunlight__c = (plant.CAMPX__Garden__c != null && gardenMap.containsKey(plant.CAMPX__Garden__c)) ? gardenMap.get(plant.CAMPX__Garden__c).CAMPX__Sun_Exposure__c : 'Partial Sun';
    }

    /**
     * Extracts and returns a set of unique garden Ids referenced by the given plants.
     *
     * This helper scans the list of plant records and gathers the Ids of any gardens
     * they are assigned to. Null garden references are ignored.
     *
     * @param plants  The list of plant records to inspect.
     * @return        A Set<Id> containing unique garden Ids referenced by the plants.
     */
    private Set<Id> createGardenIdSet(List<CAMPX__Plant__c> plants) {
        Set<Id> gardenIds = new Set<Id>();
        if (plants != null) {
            for (CAMPX__Plant__c plant : plants) {
                if (plant.CAMPX__Garden__c != null || (Trigger.isBefore && Trigger.isInsert)) {
                    gardenIds.add(plant.CAMPX__Garden__c);
                }
            }
        }
        return gardenIds;
    }

    /**
     * Initializes a list of plant records by populating default field values.
     *
     * This method collects all referenced garden Ids, queries the corresponding
     * garden records, and then applies garden-specific or default initialization
     * logic to each plant by calling initializeFields().
     *
     * Performs no action if no valid garden Ids are found.
     *
     * @param plants  The list of CAMPX__Plant__c records to initialize.
     */
    private void initializePlants(List<CAMPX__Plant__c> plants) {
        Set<Id> gardenIds = createGardenIdSet(plants);
        if (gardenIds.isEmpty()) return;
        Map<Id, CAMPX__Garden__c> gardenMap = new Map<Id, CAMPX__Garden__c>([SELECT Id, CAMPX__Sun_Exposure__c FROM CAMPX__Garden__c WHERE Id IN :gardenIds]);
        for (CAMPX__Plant__c plant : plants) {
            initializeFields(plant, gardenMap);
        }
    }

    /**
     * Determines which gardens are affected by changes in plant assignments.
     *
     * This method compares old and new versions of plant records to identify
     * gardens whose plant counts may need to be recalculated. A garden is
     * considered affected when a plant is moved into or out of it.
     *
     * Special handling:
     *   - If both old and new lists are provided, each pair is compared by index.
     *   - If only oldPlants is provided, all referenced gardens are included.
     *   - If only newPlants is provided, all referenced gardens are included.
     *
     * @param oldPlants  The original list of plant records (from Trigger.old), or null.
     * @param newPlants  The updated list of plant records (from Trigger.new), or null.
     * @return           A Set<Id> of garden Ids whose plant counts need recalculation.
     */
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

    /**
     * Recalculates and updates the total plant count for affected gardens.
     *
     * This method identifies all gardens impacted by plant assignment changes,
     * queries the current count of plants per garden via an aggregate query,
     * and updates each garden's CAMPX__Total_Plant_Count__c field accordingly.
     *
     * Gardens with no remaining plants are updated with a count of zero.
     *
     * Performs one bulk UPDATE operation for efficiency and trigger safety.
     *
     * @param oldPlants  The prior versions of plant records (Trigger.old), or null.
     * @param newPlants  The new versions of plant records (Trigger.new), or null.
     */
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
            gardensToUpdate.add(new CAMPX__Garden__c(Id = gardenId, CAMPX__Total_Plant_Count__c = total));
        }

        if (!gardensToUpdate.isEmpty()) {
            update gardensToUpdate;
        }
    }

    private void updateGardenUnhealthyPlantCount(List<CAMPX__Plant__c> oldPlants, List<CAMPX__Plant__c> newPlants) {
        Set<Id> affectedGardenIds = getAffectedGardenIds(oldPlants, newPlants);
        
        if (affectedGardenIds.isEmpty()) return;

        Set<String> unhealthyStatuses = new Set<String> {STATUS_SICK, STATUS_WILITING, STATUS_DECEASED};

        Map<Id, Integer> gardensUnhealthyPlantCountMap = new Map<Id, Integer>(); 
        for (AggregateResult ar : [SELECT CAMPX__Garden__c gardenId, Count(Id) total
                                   FROM CAMPX__Plant__c 
                                   WHERE CAMPX__Garden__c IN :affectedGardenIds 
                                   AND CAMPX__Status__c in :unhealthyStatuses
                                   GROUP BY CAMPX__Garden__c]
            ) 
        {
            gardensUnhealthyPlantCountMap.put((Id)ar.get('gardenId'), (Integer)ar.get('total'));
        }
        
        List<CAMPX__Garden__c> gardensToUpdate = new List<CAMPX__Garden__c>();
        for (Id gardenId : affectedGardenIds) {
            Integer total = gardensUnhealthyPlantCountMap.containsKey(gardenId) ? gardensUnhealthyPlantCountMap.get(gardenId) : 0;
            gardensToUpdate.add(new CAMPX__Garden__c(Id = gardenId, CAMPX__Total_Unhealthy_Plant_Count__c = total));
        }

        if (!gardensToUpdate.isEmpty()) 
            update gardensToUpdate;
    }
}