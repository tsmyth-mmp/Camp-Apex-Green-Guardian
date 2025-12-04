public with sharing class GardenTriggerHelper {
    private static final String ACQUIRE_PLANTS_SUBJECT = 'Acquire Plants';
    private static final String STATUS_AWAITING_RESOURCES = 'Awaiting Resources';
    private static final String STATUS_COMPLETED = 'Completed';
    
    public void processBeforeInsert(List<CAMPX__Garden__c> newRecords) {
            initializeFields(newRecords);
    }

   public void processBeforeUpdate(List<CAMPX__Garden__c> oldRecords, List<CAMPX__Garden__c> newRecords, Map<Id, CAMPX__Garden__c> oldMap, Map<Id, CAMPX__Garden__c> newMap) {
        handleManagerChange(newRecords, oldMap);
    }

    public void processBeforeDelete(List<CAMPX__Garden__c> oldRecords, Map<Id, CAMPX__Garden__c> oldMap) {

    }


    public void processAfterInsert(List<CAMPX__Garden__c> newRecords, Map<Id, CAMPX__Garden__c> newGardenMap) {
        handleNewTaskCreation(newRecords);
        calcCapacity(newRecords, null);
    }

    public void processAfterUpdate(List<CAMPX__Garden__c> oldRecords, List<CAMPX__Garden__c> newRecords, Map<Id, CAMPX__Garden__c> oldMap, Map<Id, CAMPX__Garden__c> newMap) {
        deleteOpenTasksWithoutReplacementManager(oldRecords, newRecords, oldMap, newMap);
        calcCapacity(newRecords, oldMap);
    }

     /**
     * Initializes default field values on a garden record if null or blank.
     *
     * @param garden CAMPX__Garden__c record to initialize.
     */
    private void initializeFields(List<CAMPX__Garden__c> gardens) {
        for (CAMPX__Garden__c garden : gardens) {
            garden.CAMPX__Status__c = garden.CAMPX__Status__c ?? STATUS_AWAITING_RESOURCES;
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
            Subject = ACQUIRE_PLANTS_SUBJECT);
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
        List<Task> tasks = queryTasks(gardenIdsForManagerChange, ACQUIRE_PLANTS_SUBJECT, null);

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
                
                if (hasAnyTask) {
                    for (Task t : tasksByGardenId.get(garden.Id)) {
                        if (t.Status != STATUS_COMPLETED) { // skip completed tasks
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
    private void deleteOpenTasksWithoutReplacementManager(List<CAMPX__Garden__c> oldRecords, List<CAMPX__Garden__c> newRecords, Map<Id, CAMPX__Garden__c> oldMap, Map<Id, CAMPX__Garden__c> newMap) {
        Set<Id> gardenIdsWithManagerRemoved = new Set<Id>();
        
        for (CAMPX__Garden__c garden : newRecords) {
            CAMPX__Garden__c oldGarden = oldMap.get(garden.Id);
            CAMPX__Garden__c newGarden = newMap.get(garden.Id);
            if (oldGarden.CAMPX__Manager__c != null && newGarden.CAMPX__Manager__c == null) {
                gardenIdsWithManagerRemoved.add(garden.Id);
            }
        }       
        
        Set<String> excludedStatuses = new Set<String>{STATUS_COMPLETED};
        List<Task> tasksToDelete = queryTasks(gardenIdsWithManagerRemoved, ACQUIRE_PLANTS_SUBJECT, excludedStatuses);
        
        if (!tasksToDelete.isEmpty()) {
            delete tasksToDelete;
        }
    }

    private void calcCapacity(List<CAMPX__Garden__c> gardens, Map<Id, CAMPX__Garden__c> oldMap) {
        List<CAMPX__Garden__c> gardensToUpdate = new List<CAMPX__Garden__c>();
        List<CAMPX__Garden__c> gardensToInsert = new List<CAMPX__Garden__c>();
        for (CAMPX__Garden__c garden : gardens) {
            if (oldMap != null && oldMap.containsKey(garden.Id)) {
                CAMPX__Garden__c oldGarden = oldMap.get(garden.Id);
                if (garden.CAMPX__Max_Plant_Count__c != oldGarden.CAMPX__Max_Plant_Count__c 
                    || garden.CAMPX__Total_Plant_Count__c != oldGarden.CAMPX__Total_Plant_Count__c) {
                    gardensToUpdate.add(new CAMPX__Garden__c(Id =garden.Id, 
                                                             CAMPX__Capacity__c = garden.CAMPX__Max_Plant_Count__c == 0
                                                              || garden.CAMPX__Total_Plant_Count__c == 0 
                                                              || garden.CAMPX__Max_Plant_Count__c == null 
                                                              || garden.CAMPX__Total_Plant_Count__c == null
                                                                ? 0 
                                                                : (garden.CAMPX__Total_Plant_Count__c / garden.CAMPX__Max_Plant_Count__c) * 100));
                }
            } else {
                 gardensToUpdate.add(new CAMPX__Garden__c(Id =garden.Id, 
                                                          CAMPX__Capacity__c = garden.CAMPX__Max_Plant_Count__c == 0 
                                                          || garden.CAMPX__Total_Plant_Count__c == 0 
                                                          || garden.CAMPX__Max_Plant_Count__c == null 
                                                          || garden.CAMPX__Total_Plant_Count__c == null
                                                            ? 0 
                                                            : (garden.CAMPX__Total_Plant_Count__c / garden.CAMPX__Max_Plant_Count__c) * 100));
            }
        }

        if (!gardensToUpdate.isEmpty()) {
            update gardensToUpdate;
        }
        if (!gardensToInsert.isEmpty()) {
            insert gardensToInsert;
        }
    }
}