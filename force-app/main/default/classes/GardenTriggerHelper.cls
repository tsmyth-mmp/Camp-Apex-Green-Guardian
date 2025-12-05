public with sharing class GardenTriggerHelper {
    public void processBeforeInsert(List<CAMPX__Garden__c> newRecords) {
        initializeFields(newRecords);
        validationCheck(newRecords);
        refreshGardenCalculatedFields(newRecords, null);
        setStatusByCondition(newRecords, null);
    }

    public void processBeforeUpdate(
        List<CAMPX__Garden__c> oldRecords,
        List<CAMPX__Garden__c> newRecords, 
        Map<Id, CAMPX__Garden__c> oldMap, 
        Map<Id, CAMPX__Garden__c> newMap
    ) {
        validationCheck(newRecords);
        handleManagerChange(newRecords, oldMap);
        refreshGardenCalculatedFields(newRecords, oldMap);
        setStatusByCondition(newRecords, oldMap);
    }

    public void processBeforeDelete(List<CAMPX__Garden__c> oldRecords, Map<Id, CAMPX__Garden__c> oldMap) {

    }


    public void processAfterInsert(List<CAMPX__Garden__c> newRecords, Map<Id, CAMPX__Garden__c> newGardenMap) {
        handleNewTaskCreation(newRecords);
       
    }

    public void processAfterUpdate(
        List<CAMPX__Garden__c> oldRecords,
        List<CAMPX__Garden__c> newRecords,
        Map<Id, CAMPX__Garden__c> oldMap, 
        Map<Id, CAMPX__Garden__c> newMap
        ) {
        deleteOpenTasksWithoutReplacementManager(oldRecords, newRecords, oldMap, newMap);
    }

    /*************************************HELPER METHODS*************************************/

     /**
     * Initializes default field values on a garden record if null or blank.
     *
     * @param garden CAMPX__Garden__c record to initialize.
     */
    private void initializeFields(List<CAMPX__Garden__c> gardens) {
        for (CAMPX__Garden__c garden : gardens) {
            garden.CAMPX__Max_Plant_Count__c = garden.CAMPX__Max_Plant_Count__c ?? 100;
            garden.CAMPX__Minimum_Plant_Count__c = garden.CAMPX__Minimum_Plant_Count__c ?? 1;
            garden.CAMPX__Total_Plant_Count__c = garden.CAMPX__Total_Plant_Count__c ?? 0;
            garden.CAMPX__Total_Unhealthy_Plant_Count__c = garden.CAMPX__Total_Unhealthy_Plant_Count__c ?? 0;
            if (garden.CAMPX__Manager__c != null) garden.CAMPX__Manager_Start_Date__c = Date.today();
        }
    }

    /**
     * Creates a new Task for a given garden.
     *
     * @param garden CAMPX__Garden__c record for which to create a task.
     * @return Task object populated with WhatId, OwnerId, and Subject.
     */
    private Task createNewTask(CAMPX__Garden__c garden) {
        Task newTask = new Task( 
            WhatId = garden.Id,
            OwnerId = garden.CAMPX__Manager__c,
            Subject = TaskConstants.getDefaultSubjectLabel());
        return newTask;
    }

    private void handleNewTaskCreation(List<CAMPX__Garden__c> gardens) {
        List<Task> newTasks = new List<Task>();
        for (CAMPX__Garden__c garden : gardens) {
            if (garden.CAMPX__Manager__c != null) {
                newTasks.add(createNewTask(garden));
            }
        }
        
        if (!newTasks.isEmpty()){
            insert(newTasks);
        }
    }

    /**
     * Returns a set of garden Ids where the manager has changed.
     *
     * @param newRecords List of updated CAMPX__Garden__c records.
     * @param oldMap Map of original garden records keyed by Id.
     * @return Set<Id> of garden records with manager changes.
     */
    private Set<Id> getGardenIdsWithNewOrChangedManager(List<CAMPX__Garden__c> newRecords, Map<Id, CAMPX__Garden__c> oldMap) {
        Set<Id> gardenIdsForManagerChange = new Set<Id>();
        for (CAMPX__Garden__c garden : newRecords) {
            CAMPX__Garden__c oldGarden = oldMap.get(garden.Id);
            if (oldGarden.CAMPX__Manager__c != garden.CAMPX__Manager__c && garden.CAMPX__Manager__c != null) {
                gardenIdsForManagerChange.add(garden.Id);
            }
        }
        return gardenIdsForManagerChange;
    }

    /**
     * Queries tasks by subject for the given gardens with optional status exclusions.
     *
     * @param gardenIds Set of CAMPX__Garden__c Ids to query tasks for.
     * @param subject Task subject to filter by (e.g., 'Acquire Plants').
     * @param excludedStatuses Optional set of Status values to exclude; can be null.
     * @return List<Task> matching the criteria.
     */
    private List<Task> queryTasks(Set<Id> gardenIds, String subject, Set<String> excludedStatuses) {
        if (gardenIds.isEmpty()) {
            return new List<Task>();
        }

        List<Task> tasks;
        if (excludedStatuses == null || excludedStatuses.isEmpty()) {
            tasks = [
                    SELECT Id, WhatId, OwnerId, Subject, Status 
                    FROM Task 
                    WHERE WhatId IN :gardenIds 
                        AND Subject = :subject 
                    ];
        } else {
            tasks = [
                    SELECT Id, WhatId, OwnerId, Subject, Status 
                    FROM Task 
                    WHERE WhatId IN :gardenIds 
                        AND Subject = :subject 
                        AND Status NOT IN :excludedStatuses
                    ];
        }
        
        return tasks;
    }
    
    /**
     * Handles changes to garden managers:
     *  - Inserts new tasks for gardens with newly assigned managers.
     *  - Updates OwnerId on existing tasks if the manager changed, skipping completed tasks.
     *
     * @param newRecords List of updated CAMPX__Garden__c records.
     * @param oldMap Map of original garden records keyed by Id.
     */
    private void handleManagerChange(List<CAMPX__Garden__c> newRecords, Map<Id, CAMPX__Garden__c> oldMap) {
        List<Task> tasksToInsert = new List<Task>();
        List<Task> tasksToUpdate = new List<Task>();
        
        // Collect garden IDs where manager changed 
        Set<Id> gardenIdsForManagerChange = getGardenIdsWithNewOrChangedManager(newRecords, oldMap);

        // Query existing 'Acquire Plants' tasks for all relevant gardens
        List<Task> tasks = queryTasks(gardenIdsForManagerChange, TaskConstants.getDefaultSubjectLabel(), null);

        Map<Id, List<Task>> tasksByGardenId = new Map<Id, List<Task>>();
        for (Task t : tasks) {
            if (!tasksByGardenId.containsKey(t.WhatId)) {
                tasksByGardenId.put(t.WhatId, new List<Task>());
            }    
            tasksByGardenId.get(t.WhatId).add(t);
        }

        // Process updates per garden
        for (CAMPX__Garden__c garden : newRecords) {
            CAMPX__Garden__c oldGarden = oldMap.get(garden.Id);
            Boolean managerChanged = garden.CAMPX__Manager__c != oldGarden.CAMPX__Manager__c;
            Boolean managerAssigned = oldGarden.CAMPX__Manager__c == null && garden.CAMPX__Manager__c != null;
            
            
            // Case 1: Manager assigned for the first time
            if (managerAssigned) {
                tasksToInsert.add(createNewTask(garden));
            }
            
            // Case 2: Manager changed
            if (managerChanged) {
                Boolean hasAnyTask = tasksByGardenId.containsKey(garden.id);
                String statusToCheck = TaskConstants.Status.Completed.name();
                
                if (hasAnyTask) {
                    for (Task t : tasksByGardenId.get(garden.Id)) {
                        if (t.Status != statusToCheck) { // skip completed tasks
                            t.OwnerId = garden.CAMPX__Manager__c;
                            tasksToUpdate.add(t);
                        }
                    }   
                }
            }

            // Set manager start date
            if (managerChanged && garden.CAMPX__Manager__c != null) {
                garden.CAMPX__Manager_Start_Date__c = Date.today();
            }
            else if (managerChanged && garden.CAMPX__Manager__c == null) {
                garden.CAMPX__Manager_Start_Date__c = null;
            }
        }
        
        // Bulk DML
        if (!tasksToUpdate.isEmpty()) {
             update tasksToUpdate;
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    /**
     * Deletes all open "Acquire Plants" tasks for gardens whose manager has been removed
     * without a replacement. Completed tasks are preserved.
     *
     * This method should be called in an after-update context, after garden records
     * have had their manager removed. It ensures the system does not retain
     * open tasks for gardens with no assigned manager.
     *
     * @param oldRecords List of original CAMPX__Garden__c records before update.
     * @param newRecords List of updated CAMPX__Garden__c records after update.
     * @param oldMap Map of original garden records keyed by Id.
     * @param newMap Map of updated garden records keyed by Id.
     */
    private void deleteOpenTasksWithoutReplacementManager(
        List<CAMPX__Garden__c> oldRecords, 
        List<CAMPX__Garden__c> newRecords, 
        Map<Id, CAMPX__Garden__c> oldMap, 
        Map<Id, CAMPX__Garden__c> newMap
    ) {
        Set<Id> gardenIdsWithManagerRemoved = new Set<Id>();
        
        for (CAMPX__Garden__c garden : newRecords) {
            CAMPX__Garden__c oldGarden = oldMap.get(garden.Id);
            CAMPX__Garden__c newGarden = newMap.get(garden.Id);
            if (oldGarden.CAMPX__Manager__c != null && newGarden.CAMPX__Manager__c == null) {
                gardenIdsWithManagerRemoved.add(garden.Id);
            }
        }       
        
        Set<String> excludedStatuses = new Set<String>();
        for (TaskConstants.Status s : TaskConstants.EXCLUDED_STATUSES) {
            excludedStatuses.add(TaskConstants.getStatusLabel(s));
        }

        List<Task> tasksToDelete = queryTasks(gardenIdsWithManagerRemoved, TaskConstants.getDefaultSubjectLabel(), excludedStatuses);
        
        if (!tasksToDelete.isEmpty()) {
            delete tasksToDelete;
        }
    }

    /**
     * Calculates the capacity percentage for a garden based on its maximum and total plant counts.
     *
     * Capacity is defined as: (Total_Plant_Count / Max_Plant_Count) * 100
     *
     * If the maximum plant count is null or zero, or if the total plant count is null,
     * the method returns 0 to avoid invalid arithmetic.
     *
     * @param garden  The CAMPX__Garden__c record for which capacity should be calculated.
     * @return        A Decimal representing the garden's capacity percentage (0–100+).
     */
    private Decimal computeGardenCapacity(CAMPX__Garden__c garden) {
        if (garden.CAMPX__Max_Plant_Count__c == null 
            || garden.CAMPX__Max_Plant_Count__c == 0
            || garden.CAMPX__Total_Plant_Count__c == null ) {
            return 0;
        } 
        return ((Decimal)garden.CAMPX__Total_Plant_Count__c / (Decimal)garden.CAMPX__Max_Plant_Count__c) * 100;                
    }

    /**
     * Refreshes the calculated fields (Capacity and Health Index) for a list of gardens.
     *
     * This method compares the current garden records against their previous values 
     * (from oldMap) and only recalculates Capacity and Health Index when the relevant 
     * input fields have changed:
     *   - CAMPX__Max_Plant_Count__c
     *   - CAMPX__Total_Plant_Count__c
     *   - CAMPX__Total_Unhealthy_Plant_Count__c
     *
     * It avoids unnecessary DML by updating a record only if the newly computed 
     * values differ from the stored values. All updates are performed in a single 
     * bulk-safe operation.
     *
     * @param gardens  List of CAMPX__Garden__c records from the trigger context (new or updated).
     * @param oldMap   Map of prior versions of these garden records (Trigger.oldMap), or null if not available.
     */
    private void refreshGardenCalculatedFields(List<CAMPX__Garden__c> gardens, Map<Id, CAMPX__Garden__c> oldMap) {
        for (CAMPX__Garden__c garden : gardens) {
            CAMPX__Garden__c oldGarden = (oldMap != null && oldMap.containsKey(garden.Id)) ? oldMap.get(garden.Id) : null;
            Boolean needsRecalc = oldGarden == null 
                ||garden.CAMPX__Max_Plant_Count__c != oldGarden.CAMPX__Max_Plant_Count__c 
                || garden.CAMPX__Total_Plant_Count__c != oldGarden.CAMPX__Total_Plant_Count__c
                || garden.CAMPX__Total_Unhealthy_Plant_Count__c != oldGarden.CAMPX__Total_Unhealthy_Plant_Count__c;
            
            if (!needsRecalc) continue;

            Decimal newCapacity = computeGardenCapacity(garden);
            Decimal newHealthIndex = computeGardenHealthIndex(garden);

            if (oldGarden == null || oldGarden.CAMPX__Capacity__c != newCapacity) garden.CAMPX__Capacity__c = newCapacity;
            
            if (oldGarden == null || oldGarden.CAMPX__Health_Index__c != newHealthIndex) garden.CAMPX__Health_Index__c = newHealthIndex;    
        }
    }

    private Decimal computeGardenHealthIndex(CAMPX__Garden__c garden) {
        Decimal totalPlantCount = (Decimal)garden.CAMPX__Total_Plant_Count__c;
        Decimal totalUnhealthyCount = (Decimal)garden.CAMPX__Total_Unhealthy_Plant_Count__c;
        if (totalPlantCount == null || totalPlantCount <= 0) return 0;
        return ((totalPlantCount - totalUnhealthyCount) / totalPlantCount) * 100;
    }

    private void setStatusByCondition(List<CAMPX__Garden__c> gardens, Map<Id, CAMPX__Garden__c> oldMap) {
        for (CAMPX__Garden__c garden : gardens) {
            if (garden.CAMPX__Status__c == GardenConstants.getStatusLabel(GardenConstants.Status.PermanentClosure)) continue;
            
            CAMPX__Garden__c oldGarden = (oldMap != null && oldMap.containsKey(garden.Id)) ? oldMap.get(garden.Id) : null;
            Boolean needsReset = oldGarden == null 
                || garden.CAMPX__Capacity__c != oldGarden.CAMPX__Capacity__c 
                || garden.CAMPX__Health_Index__c != oldGarden.CAMPX__Health_Index__c
                || garden.CAMPX__Minimum_Plant_Count__c != oldGarden.CAMPX__Minimum_Plant_Count__c
                ||  garden.CAMPX__Total_Plant_Count__c != oldGarden.CAMPX__Total_Plant_Count__c;
            
            if (!needsReset) continue;
            
            if (
                (100 >= garden.CAMPX__Capacity__c && garden.CAMPX__Capacity__c >= 70)
                && garden.CAMPX__Total_Plant_Count__c >= garden.CAMPX__Minimum_Plant_Count__c 
                && garden.CAMPX__Health_Index__c >= 70
            ) {
                garden.CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.Operational);
            } 
            else if (garden.CAMPX__Capacity__c == 0) {
                garden.CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.TemporaryClosure);
            } 
            else if (garden.CAMPX__Capacity__c > 100) {
                garden.CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.OverCapacity);
            } 
            else if (
                (70 > garden.CAMPX__Capacity__c && garden.CAMPX__Capacity__c > 0) 
                || 70 > garden.CAMPX__Health_Index__c
                || garden.CAMPX__Minimum_Plant_Count__c > garden.CAMPX__Total_Plant_Count__c
            ) {
                garden.CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.AwaitingResources);
            }        
        } 
    }

    private void checkForNegativeValues(CAMPX__Garden__c garden) {
        if (garden.CAMPX__Total_Plant_Count__c < 0) {
            garden.addError('Plant Count fields must be greater than or equal to zero');
        }
        if (garden.CAMPX__Total_Unhealthy_Plant_Count__c < 0) {
            garden.addError('Plant Count fields must be greater than or equal to zero');
        }
        if (garden.CAMPX__Minimum_Plant_Count__c < 0) {
            garden.addError('Plant Count fields must be greater than or equal to zero');
        }
        if (garden.CAMPX__Max_Plant_Count__c < 0) {
            garden.addError('Plant Count fields must be greater than or equal to zero');
        }
    }

    private void checkForBlankValues(CAMPX__Garden__c garden) {
        if (garden.CAMPX__Total_Plant_Count__c > 0 
            && (garden.CAMPX__Max_Plant_Count__c == null 
            || garden.CAMPX__Minimum_Plant_Count__c == null)
        ) {
            garden.addError('Maximum and Minimum Plant Count fields cannot be blank when there are plants in the Garden.');
        }  
    }

    private void checkForValidRange(CAMPX__Garden__c garden) {
        if ((garden.CAMPX__Max_Plant_Count__c != null || garden.CAMPX__Minimum_Plant_Count__c != null ) 
            && (garden.CAMPX__Max_Plant_Count__c < garden.CAMPX__Minimum_Plant_Count__c)
        ) {
            garden.addError('The Maximum Plant Count must be greater than or equal to the Minimum Plant Count');
        }
    }

    private void validationCheck(List<CAMPX__Garden__c> gardens) {
        for (CAMPX__Garden__c garden : gardens) {
            checkForNegativeValues(garden);
            checkForBlankValues(garden);
            checkForValidRange(garden);
        }
    }
}