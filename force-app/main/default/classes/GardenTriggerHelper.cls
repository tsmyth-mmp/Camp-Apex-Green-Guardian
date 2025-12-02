public with sharing class GardenTriggerHelper {
    public void processBeforeInsert(List<CAMPX__Garden__c> gardens) {
        for (CAMPX__Garden__c garden : gardens) {
            initalizeFields(garden);
        }
    }

    public void processBeforeUpdate(List<CAMPX__Garden__c> oldRecords, List<CAMPX__Garden__c> newRecords, Map<Id, CAMPX__Garden__c> oldMap, Map<Id, CAMPX__Garden__c> newMap) {
        List<Task> newTasks = new List<Task>();
        Set<Task> oldTasksSet = new Set<Task>();
        for (CAMPX__Garden__c garden : (List<CAMPX__Garden__c>) newRecords) {
            CAMPX__Garden__c oldGarden = oldMap.get(garden.Id);
            
            if (oldGarden.CAMPX__Manager__c == null && garden.CAMPX__Manager__c != null) {
                newTasks.add(createNewTask(garden));
            }

            if (oldGarden.CAMPX__Manager__c != null && garden.CAMPX__Manager__c != oldGarden.CAMPX__Manager__c) {
                oldTasksSet = createOldTaskIdSet(garden);
                newTasks.addAll(updateTask(garden, oldTasksSet));
            }
        }
        
        if (!newTasks.isEmpty()){
            upsert(newTasks);
        }
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

    private void initalizeFields(CAMPX__Garden__c garden) {
        garden.CAMPX__Status__c = String.isNotBlank(garden.CAMPX__Status__c) ? garden.CAMPX__Status__c : 'Awaiting Resources';
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

    private Set<Task> updateTask(CAMPX__Garden__c garden, Set<Task> tasksToUpdate) {
        for (Task task : tasksToUpdate) {
            task.OwnerId = garden.CAMPX__Manager__c;
        }
        return tasksToUpdate;
    }

    private Set<Task> createOldTaskIdSet(CAMPX__Garden__c garden) {
        Set<Task> oldTasksSet = new Set<Task>();
        for (Task task : [SELECT Id, WhatId, OwnerId, Subject, Status
                                      FROM Task 
                                      WHERE WhatId = :garden.id])
        {
            if (task.Subject == 'Acquire Plants' && task.Status != 'Completed') {
                oldTasksSet.add(task);
            }
        }

        return oldTasksSet;
    }
}