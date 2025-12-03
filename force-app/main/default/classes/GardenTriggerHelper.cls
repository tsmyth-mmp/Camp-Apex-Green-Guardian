public with sharing class GardenTriggerHelper {
    public void processBeforeInsert(List<CAMPX__Garden__c> gardens) {
        for (CAMPX__Garden__c garden : gardens) {
            initializeFields(garden);
        }
    }

   public void processBeforeUpdate(List<CAMPX__Garden__c> oldRecords, List<CAMPX__Garden__c> newRecords, Map<Id, CAMPX__Garden__c> oldMap, Map<Id, CAMPX__Garden__c> newMap) {
        handleManagerChange(newRecords, oldMap);
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

    private void initializeFields(CAMPX__Garden__c garden) {
        garden.CAMPX__Status__c = garden.CAMPX__Status__c != null ? garden.CAMPX__Status__c : 'Awaiting Resources';
        garden.CAMPX__Max_Plant_Count__c = garden.CAMPX__Max_Plant_Count__c != null ? garden.CAMPX__Max_Plant_Count__c : 100;
        garden.CAMPX__Minimum_Plant_Count__c = garden.CAMPX__Minimum_Plant_Count__c != null ? garden.CAMPX__Minimum_Plant_Count__c : 1;
        garden.CAMPX__Total_Plant_Count__c = garden.CAMPX__Total_Plant_Count__c != null ? garden.CAMPX__Total_Plant_Count__c : 0;
        garden.CAMPX__Total_Unhealthy_Plant_Count__c = garden.CAMPX__Total_Unhealthy_Plant_Count__c != null ? garden.CAMPX__Total_Unhealthy_Plant_Count__c : 0;
    }

    private Task createNewTask(CAMPX__Garden__c garden) {
        Task newTask = new Task( 
            WhatId = garden.Id,
            OwnerId = garden.CAMPX__Manager__c,
            Subject = 'Acquire Plants');
        return newTask;
    }

    private void handleManagerChange(List<CAMPX__Garden__c> newRecords, Map<Id, CAMPX__Garden__c> oldMap) {
        List<Task> tasksToInsert = new List<Task>();
        List<Task> tasksToUpdate = new List<Task>();

        // Step 1: Collect garden IDs where manager changed
        Set<Id> gardenIdsForManagerChange = new Set<Id>();
        for (CAMPX__Garden__c garden : newRecords) {
            CAMPX__Garden__c oldGarden = oldMap.get(garden.Id);
            
            if (oldGarden.CAMPX__Manager__c != garden.CAMPX__Manager__c && garden.CAMPX__Manager__c != null) {
                gardenIdsForManagerChange.add(garden.Id);
            }
        }

        // Step 2: Query existing 'Acquire Plants' tasks for all relevant gardens
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

        // Step 3: Process updates per garden
        for (CAMPX__Garden__c garden : newRecords) {
            CAMPX__Garden__c oldGarden = oldMap.get(garden.Id);

            // Case 1: Manager assigned for the first time
            if (oldGarden.CAMPX__Manager__c == null && garden.CAMPX__Manager__c != null) {
                tasksToInsert.add(createNewTask(garden));
            }

           // Case 2: Manager changed
            if (oldGarden.CAMPX__Manager__c != null && garden.CAMPX__Manager__c != oldGarden.CAMPX__Manager__c) {
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

        // Step 4: Bulk DML
        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }

        if (!tasksToUpdate.isEmpty()) {
            update tasksToUpdate;
        }
    }
}