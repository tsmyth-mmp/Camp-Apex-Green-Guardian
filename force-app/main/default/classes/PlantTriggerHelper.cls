public with sharing class PlantTriggerHelper {
    public void processBeforeInsert(List<CAMPX__Plant__c> newRecords) {
        initializePlants(newRecords);
        checkForClosedGardens(null, newRecords);   
    }

    public void processBeforeUpdate(
        List<CAMPX__Plant__c> oldRecords, 
        List<CAMPX__Plant__c> newRecords, 
        Map<Id, CAMPX__Plant__c> oldMap, 
        Map<Id, CAMPX__Plant__c> newMap 
    ) {
        checkForClosedGardens(oldRecords, newRecords);
    }

    public void processAfterInsert(List<CAMPX__Plant__c> newRecords, Map<Id, CAMPX__Plant__c> newMap) {
        updateGardenTotalPlantCount(null, newRecords);
        updateGardenUnhealthyPlantCount(null, newRecords);
    }

    public void processAfterUpdate(
        List<CAMPX__Plant__c> oldRecords,
        List<CAMPX__Plant__c> newRecords,
        Map<Id, CAMPX__Plant__c> oldMap,
        Map<Id, CAMPX__Plant__c> newMap
         
    ) {
        updateGardenTotalPlantCount(oldRecords, newRecords);
        updateGardenUnhealthyPlantCount(oldRecords, newRecords);
    }

    public void processAfterDelete(List<CAMPX__Plant__c> oldRecords, Map<Id, CAMPX__Plant__c> oldMap) {
        updateGardenTotalPlantCount(oldRecords, null);
        updateGardenUnhealthyPlantCount(oldRecords, null);
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
        plant.CAMPX__Soil_Type__c = String.isNotBlank(plant.CAMPX__Soil_Type__c) ? plant.CAMPX__Soil_Type__c : PlantConstants.getDefaultSoilTypeLabel();
        plant.CAMPX__Water__c = plant.CAMPX__Water__c != null ? plant.CAMPX__Water__c : PlantConstants.getDefaultWaterLabel();
        plant.CAMPX__Sunlight__c = (plant.CAMPX__Garden__c != null && gardenMap.containsKey(plant.CAMPX__Garden__c)) 
                                    ? gardenMap.get(plant.CAMPX__Garden__c).CAMPX__Sun_Exposure__c 
                                    : PlantConstants.getDefaultSunlightLabel();
    }

    /**
      * Extracts a set of unique garden Ids referenced by a list of plant records.
      *
      * This helper scans the provided list and gathers the Ids of gardens assigned
      * to each plant, ignoring null references. Useful for bulk operations and inserts.
      *
      * @param plants  The list of plant records to inspect.
      * @return        A Set<Id> containing unique garden Ids referenced by the plants.
      */
    private Set<Id> createGardenIdSet(List<CAMPX__Plant__c> plants) {
        Set<Id> gardenIds = new Set<Id>();
        if (plants != null) {
            for (CAMPX__Plant__c plant : plants) {
                if (plant.CAMPX__Garden__c != null || (Trigger.isBefore && Trigger.isInsert)) { // need to check if trigger is before and insert since gardens can be null
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
     * Determines which gardens are affected by changes in plant records.
     *
     * This method compares old and new versions of plant records to identify
     * gardens whose unhealthy plant counts may need to be recalculated. A garden
     * is considered affected when a plant is moved, its status changes, or plants
     * are inserted or deleted.
     *
     * Special handling:
     *   - If both oldPlants and newPlants are provided, they are compared by index.
     *   - The larger list is used to prevent index errors when list sizes differ.
     *   - If only oldPlants is provided (delete), all referenced gardens are included.
     *   - If only newPlants is provided (insert), all referenced gardens are included.
     *
     * @param oldPlants  The original list of plant records (Trigger.old), or null.
     * @param newPlants  The updated list of plant records (Trigger.new), or null.
     * @return           A Set<Id> of garden Ids whose unhealthy plant counts may have changed.
     */
    private Set<Id> getAffectedGardenIds(List<CAMPX__Plant__c> oldPlants, List<CAMPX__Plant__c> newPlants) {
        Set<Id> gardenIds = new Set<Id>();
        
        if (newPlants != null) {
            for (CAMPX__Plant__c plant : newPlants) {
                if (plant.CAMPX__Garden__c != null) {
                    gardenIds.add(plant.CAMPX__Garden__c);
                }
            }       
        }

        if (oldPlants != null) {
            for (CAMPX__Plant__c plant : oldPlants) {
                if (plant.CAMPX__Garden__c != null) {
                    gardenIds.add(plant.CAMPX__Garden__c);
            }
        }
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

    /**
     * Updates the total number of unhealthy plants for affected gardens.
     *
     * This method calculates the current number of unhealthy plants for each
     * affected garden and updates the corresponding field on the CAMPX__Garden__c
     * object. It handles bulk operations, garden moves, status changes, inserts,
     * and deletes.
     *
     * Steps:
     *   1. Determine affected gardens using getAffectedGardenIds.
     *   2. Query the current count of unhealthy plants per garden.
     *   3. Prepare garden records with updated counts.
     *   4. Perform a single bulk update for efficiency.
     *
     * Unhealthy statuses are defined by the set: STATUS_SICK, STATUS_WILTING, STATUS_DECEASED.
     *
     * @param oldPlants  The original list of plant records (Trigger.old), or null.
     * @param newPlants  The updated list of plant records (Trigger.new), or null.
     */
    private void updateGardenUnhealthyPlantCount(List<CAMPX__Plant__c> oldPlants, List<CAMPX__Plant__c> newPlants) {
        Set<Id> affectedGardenIds = getAffectedGardenIds(oldPlants, newPlants);
        
        if (affectedGardenIds.isEmpty()) return;

        Set<String> unhealthyStatuses = new Set<String>();
        for (PlantConstants.Status s : PlantConstants.UNHEALTHY_STATUSES) {
            unhealthyStatuses.add(PlantConstants.getStatusLabel(s));
        }

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

    private void checkForClosedGardens(List<CAMPX__Plant__c> oldPlants, List<CAMPX__Plant__c> newPlants) {
        Set<Id> affectedGardenIds = getAffectedGardenIds(oldPlants, newPlants);
        
        if (affectedGardenIds.isEmpty()) return;

        Map<Id, CAMPX__Garden__c> gardensById = new Map<Id, CAMPX__Garden__c>(
            [
                SELECT Id, CAMPX__Status__c 
                FROM CAMPX__Garden__c 
                WHERE Id IN :affectedGardenIds
            ]
        );

        for (Integer i = 0; i < newPlants.size(); i++) {
            CAMPX__Plant__c plant = newPlants[i];
            
            // Check if garden changed
            Id oldGardenId = (oldPlants != null && oldPlants.size() > i) ? oldPlants[i].CAMPX__Garden__c : null;
            Id newGardenId = plant.CAMPX__Garden__c;
            
            if (newGardenId == null || newGardenId == oldGardenId) continue;
            
            CAMPX__Garden__c garden = gardensById.get(newGardenId);
            if (garden == null) continue;
            
            if (garden.CAMPX__Status__c == GardenConstants.getStatusLabel(GardenConstants.Status.PermanentClosure)) {
                plant.addError('The garden selected for this plant is permanently closed. Please select a different garden.');
            }
        }
    }
}