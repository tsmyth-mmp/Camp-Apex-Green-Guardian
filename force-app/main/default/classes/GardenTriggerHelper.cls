public with sharing class GardenTriggerHelper {
    public void processBeforeInsert(List<CAMPX__Garden__c> gardens) {
        for (CAMPX__Garden__c garden : gardens) {
            initalizeFields(garden);
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
}