public with sharing class GardenTriggerHelper {
    public void processBeforeInsert(List<CAMPX__Garden__c> gardens) {
        for (CAMPX__Garden__c garden : gardens) {
            initializeFields(garden);
        }
    }

   public void processBeforeUpdate(List<CAMPX__Garden__c> oldRecords, List<CAMPX__Garden__c> newRecords, Map<Id, CAMPX__Garden__c> oldMap, Map<Id, CAMPX__Garden__c> newMap) {
        handleManagerChange(newRecords, oldMap);
    }

    public void processBeforeDelete(List<CAMPX__Garden__c> oldRecords, Map<Id, CAMPX__Garden__c> oldMap) {

    }


    public void processAfterInsert(List<CAMPX__Garden__c> gardens, Map<Id, CAMPX__Garden__c> newGardenMap) {
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

    public void processAfterUpdate(List<CAMPX__Garden__c> oldRecords, List<CAMPX__Garden__c> newRecords, Map<Id, CAMPX__Garden__c> oldMap, Map<Id, CAMPX__Garden__c> newMap) {
        deleteTask(oldRecords, newRecords, oldMap, newMap);
    }

     /**
     * Initializes default field values on a garden record if null or blank.
     *
     * @param garden CAMPX__Garden__c record to initialize.
     */
    private void initializeFields(CAMPX__Garden__c garden) {
        garden.CAMPX__Status__c = garden.CAMPX__Status__c ?? 'Awaiting Resources';
        garden.CAMPX__Max_Plant_Count__c = garden.CAMPX__Max_Plant_Count__c ?? 100;
        garden.CAMPX__Minimum_Plant_Count__c = garden.CAMPX__Minimum_Plant_Count__c ?? 1;
        garden.CAMPX__Total_Plant_Count__c = garden.CAMPX__Total_Plant_Count__c ?? 0;
        garden.CAMPX__Total_Unhealthy_Plant_Count__c = garden.CAMPX__Total_Unhealthy_Plant_Count__c ?? 0;
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
            Subject = 'Acquire Plants');
        return newTask;
    }

    /**
     * Returns a set of garden Ids where the manager has changed.
     *
     * @param newRecords List of updated CAMPX__Garden__c records.
     * @param oldMap Map of original garden records keyed by Id.
     * @return Set<Id> of garden records with manager changes.
     */
    private Set<Id> getGardenIdsWithManagerChange(List<CAMPX__Garden__c> newRecords, Map<Id, CAMPX__Garden__c> oldMap) {
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
     * Returns a map of existing 'Acquire Plants' tasks keyed by garden Id.
     *
     * @param gardenIdsForManagerChange Set of garden Ids to query tasks for.
     * @return Map<Id, List<Task>> of tasks grouped by WhatId (garden Id).
     */
    private Map<Id, List<Task>> getTasksByGardenId(Set<Id> gardenIdsForManagerChange) {
        Map<Id, List<Task>> tasksByGardenId = new Map<Id, List<Task>>();
        if (!gardenIdsForManagerChange.isEmpty()) {
            for (Task t : [SELECT Id, WhatId, OwnerId, Subject, Status 
                           FROM Task
                           WHERE WhatId IN :gardenIdsForManagerChange 
                            AND Subject = 'Acquire Plants']
                ) {
                if (!tasksByGardenId.containsKey(t.WhatId)) {
                    tasksByGardenId.put(t.WhatId, new List<Task>());
                }
                tasksByGardenId.get(t.WhatId).add(t);
            }
        }
        return tasksByGardenId;
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
        Set<Id> gardenIdsForManagerChange = getGardenIdsWithManagerChange(newRecords, oldMap);

        // Query existing 'Acquire Plants' tasks for all relevant gardens
        Map<Id, List<Task>> tasksByGardenId = getTasksByGardenId(gardenIdsForManagerChange);

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
                        if (t.Status != 'Completed') { // skip completed tasks
                            t.OwnerId = garden.CAMPX__Manager__c;
                            tasksToUpdate.add(t);
                        }
                    }   
                 }
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

    private void deleteTask(List<CAMPX__Garden__c> oldRecords, List<CAMPX__Garden__c> newRecords, Map<Id, CAMPX__Garden__c> oldMap, Map<Id, CAMPX__Garden__c> newMap) {
        List<Task> tasksToDelete = new List<Task>();
        Set<Id> gardenIdsWithManagerRemoved = new Set<Id>();
        
        for (CAMPX__Garden__c garden : newRecords) {
            CAMPX__Garden__c oldGarden = oldMap.get(garden.Id);
            CAMPX__Garden__c newGarden = newMap.get(garden.Id);
            if (oldGarden.CAMPX__Manager__c != null && newGarden.CAMPX__Manager__c == null) {
                gardenIdsWithManagerRemoved.add(garden.Id);
            }
        }

        Map<Id, List<Task>> tasksByGardenId = new Map<Id, List<Task>>();
        if (!gardenIdsWithManagerRemoved.isEmpty()) {
            for (Task t : [SELECT Id, WhatId, OwnerId, Subject, Status 
                           FROM Task
                           WHERE WhatId IN :gardenIdsWithManagerRemoved 
                            AND Subject = 'Acquire Plants'
                            AND Status != 'Completed']
                ) {
                if (!tasksByGardenId.containsKey(t.WhatId)) {
                    tasksByGardenId.put(t.WhatId, new List<Task>());
                }
                tasksByGardenId.get(t.WhatId).add(t);
            }
        }

        for (CAMPX__Garden__c garden : newRecords) {
            if (tasksByGardenId.containsKey(garden.Id)) {
                 for (Task t : tasksByGardenId.get(garden.Id)) {
                    t.OwnerId = garden.CAMPX__Manager__c;
                    tasksToDelete.add(t);
                }   
            }
        }

        if (!tasksToDelete.isEmpty()) {
            delete tasksToDelete;
        }
    }
}