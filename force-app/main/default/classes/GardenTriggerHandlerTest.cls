@isTest
private class GardenTriggerHandlerTest {

    @isTest
    static void initalizeTest_Default() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c();
        Test.startTest();
        insert(garden);
        Test.stopTest();
        CAMPX__Garden__c expected = [SELECT Id, CAMPX__Status__c, CAMPX__Max_Plant_Count__c, CAMPX__Minimum_Plant_Count__c, CAMPX__Total_Plant_Count__c, CAMPX__Total_Unhealthy_Plant_Count__c 
                                     FROM CAMPX__Garden__c WHERE Id = :garden.Id LIMIT 1];                         
        // Assert.areEqual('Awaiting Resources', expected.CAMPX__Status__c);
        Assert.areEqual(100, expected.CAMPX__Max_Plant_Count__c);
        Assert.areEqual(1, expected.CAMPX__Minimum_Plant_Count__c);
        Assert.areEqual(0, expected.CAMPX__Total_Plant_Count__c);
        Assert.areEqual(0, expected.CAMPX__Total_Unhealthy_Plant_Count__c);
    }

    @isTest
    static void initalizeTest_UserInput() {
      CAMPX__Garden__c garden = new CAMPX__Garden__c(
        //   CAMPX__Status__c = 'Operational',
          CAMPX__Max_Plant_Count__c = 1000,
          CAMPX__Minimum_Plant_Count__c = 5,
          CAMPX__Total_Plant_Count__c = 10
      );
      Test.startTest();
      insert(garden);
      Test.stopTest();
      CAMPX__Garden__c actual = [SELECT Id, CAMPX__Status__c, CAMPX__Max_Plant_Count__c, CAMPX__Minimum_Plant_Count__c, CAMPX__Total_Plant_Count__c, CAMPX__Total_Unhealthy_Plant_Count__c 
                                   FROM CAMPX__Garden__c WHERE Id = :garden.Id LIMIT 1];                         
    //   Assert.areEqual('Operational', actual.CAMPX__Status__c);
      Assert.areEqual(1000, actual.CAMPX__Max_Plant_Count__c);
      Assert.areEqual(5, actual.CAMPX__Minimum_Plant_Count__c);
      Assert.areEqual(10, actual.CAMPX__Total_Plant_Count__c);
      Assert.areEqual(0, actual.CAMPX__Total_Unhealthy_Plant_Count__c);
    }

    @isTest
    static void createTaskOnInsertTest(){
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Manager__c = u.Id);
        Test.startTest();
        insert garden;
        Test.stopTest();
        CAMPX__Garden__c insertedGarden = [SELECT Id, CAMPX__Manager__c FROM CAMPX__Garden__c WHERE Id = :garden.Id LIMIT 1];
        List<Task> tasks = [SELECT Id, WhatId, Subject, OwnerId FROM Task WHERE WhatId = :insertedGarden.Id];
        Assert.areEqual(1, tasks.size());
        Assert.areEqual(insertedGarden.id, tasks[0].WhatId);
        Assert.areEqual(insertedGarden.CAMPX__Manager__c, tasks[0].OwnerId);
        Assert.areEqual('Acquire Plants', tasks[0].Subject);
    }

    @isTest
    static void createTaskOnUpdateTest(){
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Manager__c = null);
        insert garden;
        garden.CAMPX__Manager__c = u.Id;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c insertedGarden = [SELECT Id, CAMPX__Manager__c FROM CAMPX__Garden__c WHERE Id = :garden.Id LIMIT 1];
        List<Task> tasks = [SELECT Id, WhatId, Subject, OwnerId FROM Task WHERE WhatId = :insertedGarden.Id];
        Assert.areEqual(1, tasks.size());
        Assert.areEqual(insertedGarden.id, tasks[0].WhatId);
        Assert.areEqual(insertedGarden.CAMPX__Manager__c, tasks[0].OwnerId);
        Assert.areEqual('Acquire Plants', tasks[0].Subject);
    }


    @isTest
    static void transferManagerOfTaskOnUpdateTest() {
        User u1 = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        User u2;

        System.runAs(u1) {
            Profile standardProfile = [
                SELECT Id
                FROM Profile
                WHERE Name = 'Standard User'
                LIMIT 1
            ];

            UserRole anyRole = [
                SELECT Id
                FROM UserRole
                LIMIT 1
            ];

            u2 = new User(
                Alias = 'tuser',
                Email = 'testuser+' + System.currentTimeMillis() + '@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Test',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = standardProfile.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'testuser+' + System.currentTimeMillis() + '@example.com',
                UserRoleId = anyRole.Id
            );
            insert u2;
        }

       List<CAMPX__Garden__c> gardensToInsert = new List<CAMPX__Garden__c>{
        new CAMPX__Garden__c(CAMPX__Manager__c = u1.Id),
        new CAMPX__Garden__c(CAMPX__Manager__c = u1.Id)
        };

        insert gardensToInsert;

        CAMPX__Garden__c g1 = gardensToInsert[0];
        CAMPX__Garden__c g2 = gardensToInsert[1];

       Task g1Task = [
        SELECT Id, Status
        FROM Task
        WHERE WhatId = :g1.Id
        LIMIT 1
        ];

        g1Task.Status = 'Completed';
        update g1Task;

        g1.CAMPX__Manager__c = u2.Id;
        g2.CAMPX__Manager__c = u2.Id;

        Test.startTest();
        update new List<CAMPX__Garden__c>{ g1, g2 };
        Test.stopTest();

        List<Task> openTasks = [
        SELECT Id, WhatId, OwnerId, Subject, Status
        FROM Task
        WHERE WhatId IN :new Set<Id>{ g1.Id, g2.Id }
          AND Status != 'Completed'
        ];

        System.assertEquals(1, openTasks.size(),'Only one open task should exist after manager reassignment');
        Task t = openTasks[0];
        System.assertEquals(g2.Id, t.WhatId, 'Open task should belong to Garden 2');
        System.assertEquals(u2.Id, t.OwnerId, 'Task owner should now be the new manager');
        System.assertEquals('Acquire Plants', t.Subject, 'Task subject should not change');
        System.assertNotEquals('Completed', t.Status, 'Returned task must be open');
    }

    @isTest
    static void deleteTasksWithoutReplacementManager() {
        User u1 = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        List<CAMPX__Garden__c> gardensToInsert = new List<CAMPX__Garden__c>{
            new CAMPX__Garden__c(CAMPX__Manager__c = u1.Id),
            new CAMPX__Garden__c(CAMPX__Manager__c = u1.Id)
        };

        insert gardensToInsert;

        CAMPX__Garden__c g1 = gardensToInsert[0];
        CAMPX__Garden__c g2 = gardensToInsert[1];

        Task g1Task = [
            SELECT Id, Status
            FROM Task
            WHERE WhatId = :g1.Id
            LIMIT 1
            ];

        Task g2Task = [
            SELECT Id, Status
            FROM Task
            WHERE WhatId = :g2.Id
            LIMIT 1
            ];

        g1Task.Status = 'Completed';
        update g1Task;
        g1.CAMPX__Manager__c = null;
        g2.CAMPX__Manager__c = null;
        Test.startTest();
        update new List<CAMPX__Garden__c>{ g1, g2 };
        Test.stopTest();

        List<Task> remainingTasks = [
        SELECT Id, WhatId, OwnerId, Subject, Status
        FROM Task
        WHERE WhatId IN :new Set<Id>{ g1.Id, g2.Id }
        ];
        System.assertEquals(1, remainingTasks.size(),'Only one completed task should exist after manager removal');
        Task t = remainingTasks[0];
        System.assertEquals('Completed', t.Status, 'Returned task must be completed');
        System.assertEquals('Acquire Plants', t.Subject, 'Task subject should not change');
        System.assertEquals(g1.Id, t.WhatId, 'Completed task should belong to Garden 1');
        g1 = [SELECT CAMPX__Manager__c FROM CAMPX__Garden__c WHERE Id = :g1.Id];
        g2 = [SELECT CAMPX__Manager__c FROM CAMPX__Garden__c WHERE Id = :g2.Id];
        System.assertEquals(null, g1.CAMPX__Manager__c, 'Garden 1 manager should now be removed');
        System.assertEquals(null, g2.CAMPX__Manager__c, 'Garden 2 manager should now be removed');
    }

    @isTest
    static void updateGardenNotManager() {
        User u1 = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        CAMPX__Garden__c  garden = new CAMPX__Garden__c(CAMPX__Manager__c = u1.Id);
        insert garden;
        Date currentDate = Date.today();
        garden.CAMPX__Minimum_Plant_Count__c = 5;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c actual = [SELECT Id, CAMPX__Minimum_Plant_Count__c, CAMPX__Manager__c, CAMPX__Manager_Start_Date__c FROM CAMPX__Garden__c WHERE Id = :garden.Id LIMIT 1];
        Assert.areEqual(5, actual.CAMPX__Minimum_Plant_Count__c, 'Minimum plant count should be updated');
        Assert.areEqual(garden.CAMPX__Manager__c, actual.CAMPX__Manager__c, 'Manager should not have been updated');
        Assert.areEqual(currentDate, actual.CAMPX__Manager_Start_Date__c, 'Manager start date should not have changed');
    }
    
    @isTest
    static void calcCapacity_Initial() {
      CAMPX__Garden__c garden = new CAMPX__Garden__c();
      Test.startTest();
      insert(garden);
      Test.stopTest();
      CAMPX__Garden__c actual = [SELECT Id, CAMPX__Capacity__c 
                                 FROM CAMPX__Garden__c 
                                 WHERE Id = :garden.Id 
                                 LIMIT 1];                         
      Assert.areEqual(0, actual.CAMPX__Capacity__c);
    }

    @isTest
    static void calcCapacity_IncreaseTotalPlantCount() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c();
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Capacity__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        Assert.areEqual(0, beforeUpdate.CAMPX__Capacity__c);
        garden.CAMPX__Total_Plant_Count__c = 10;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Capacity__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id 
                                        LIMIT 1];                         
        Assert.areEqual(10, afterUpdate.CAMPX__Capacity__c);
    }

    @isTest
    static void calcCapacity_DecreaseTotalPlantCount() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Total_Plant_Count__c = 100);
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Capacity__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        Assert.areEqual(100, beforeUpdate.CAMPX__Capacity__c);
        garden.CAMPX__Total_Plant_Count__c = 10;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Capacity__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id 
                                        LIMIT 1];                         
        Assert.areEqual(10, afterUpdate.CAMPX__Capacity__c);
    }

    @isTest
    static void calcCapacity_IncreaseMaxPlantCount() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Total_Plant_Count__c = 100);
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Capacity__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        Assert.areEqual(100, beforeUpdate.CAMPX__Capacity__c);
        garden.CAMPX__Max_Plant_Count__c = 1000;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Capacity__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id 
                                        LIMIT 1];                         
        Assert.areEqual(10, afterUpdate.CAMPX__Capacity__c);
    }

    @isTest
    static void calcCapacity_DecreaseMaxPlantCount() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Total_Plant_Count__c = 1);
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Capacity__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        Assert.areEqual(1, beforeUpdate.CAMPX__Capacity__c);
        garden.CAMPX__Max_Plant_Count__c = 10;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Capacity__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id LIMIT 1];                         
        Assert.areEqual(10, afterUpdate.CAMPX__Capacity__c);
    }

    @isTest
    static void calcCapacity_TotalPlantCountIsBlank() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c();
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Capacity__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        Assert.areEqual(0, beforeUpdate.CAMPX__Capacity__c);
        garden.CAMPX__Total_Plant_Count__c = null;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Capacity__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id 
                                        LIMIT 1];                         
        Assert.areEqual(0, afterUpdate.CAMPX__Capacity__c);
    }

    @isTest
    static void calcCapacity_MaxPlantCountIsZero() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c();
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Capacity__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        Assert.areEqual(0, beforeUpdate.CAMPX__Capacity__c);
        garden.CAMPX__Minimum_Plant_Count__c = 0;
        garden.CAMPX__Max_Plant_Count__c = 0;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Capacity__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id 
                                        LIMIT 1];                         
        Assert.areEqual(0, afterUpdate.CAMPX__Capacity__c);
    }

      @isTest
    static void calcHealthIndex_DecreaseTotalPlantCount() {
         CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Total_Unhealthy_Plant_Count__c = 20, CAMPX__Total_Plant_Count__c = 40);
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Health_Index__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        garden.CAMPX__Total_Plant_Count__c = 35;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Health_Index__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id 
                                        LIMIT 1];                         
        Assert.areNotEqual(beforeUpdate.CAMPX__Health_Index__c, afterUpdate.CAMPX__Health_Index__c);

    }

      @isTest
    static void calcHealthIndex_IncreaseTotalPlantCount() {
         CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Total_Unhealthy_Plant_Count__c = 20, CAMPX__Total_Plant_Count__c = 40);
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Health_Index__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        garden.CAMPX__Total_Plant_Count__c = 50;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Health_Index__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id 
                                        LIMIT 1];                         
        Assert.areNotEqual(beforeUpdate.CAMPX__Health_Index__c, afterUpdate.CAMPX__Health_Index__c);

    }

    @isTest
    static void calcHealthIndex_IncreaseTotalUnhealthyCount() {
         CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Total_Unhealthy_Plant_Count__c = 20, CAMPX__Total_Plant_Count__c = 40);
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Health_Index__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        garden.CAMPX__Total_Unhealthy_Plant_Count__c = 35;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Health_Index__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id 
                                        LIMIT 1];                         
        Assert.areEqual(12.5, afterUpdate.CAMPX__Health_Index__c);

    }

      @isTest
    static void calcHealthIndex_ZeroTotalUnhealthyCount() {
         CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Total_Unhealthy_Plant_Count__c = 20, CAMPX__Total_Plant_Count__c = 40);
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Health_Index__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        garden.CAMPX__Total_Unhealthy_Plant_Count__c = 0;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Health_Index__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id 
                                        LIMIT 1];                         
        Assert.areEqual(100, afterUpdate.CAMPX__Health_Index__c);

    }

    @isTest
    static void setStatus_CreateGardenWithZeroCapacity() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Max_Plant_Count__c = 2);
        Test.startTest();
        insert(garden);
        Test.stopTest();
        CAMPX__Garden__c query = [SELECT Id, CAMPX__Capacity__c, CAMPX__Status__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];                        
        Assert.areNotEqual(query.CAMPX__Status__c, garden.CAMPX__Status__c);
    }

    @isTest
    static void setStatus_UpdateWhenCapacityBecomesZero() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Max_Plant_Count__c = 10, CAMPX__Total_Plant_Count__c = 9);
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Capacity__c, CAMPX__Status__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        Assert.areEqual(90, beforeUpdate.CAMPX__Capacity__c);
        garden.CAMPX__Total_Plant_Count__c = 0;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Capacity__c, CAMPX__Status__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id 
                                        LIMIT 1];                         
        Assert.areEqual(0, afterUpdate.CAMPX__Capacity__c);
        Assert.areNotEqual(beforeUpdate.CAMPX__Status__c, afterUpdate.CAMPX__Status__c);
    }

    @isTest
    static void setStatus_IncreaseCapacity() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Max_Plant_Count__c = 2);
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Capacity__c, CAMPX__Status__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        garden.CAMPX__Total_Plant_Count__c = 9;
        garden.CAMPX__Max_Plant_Count__c = 10;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Capacity__c, CAMPX__Status__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id 
                                        LIMIT 1];                         
        Assert.areEqual(90, afterUpdate.CAMPX__Capacity__c);
        Assert.areEqual('Operational', afterUpdate.CAMPX__Status__c);
    }

    @isTest
    static void setStatus_OverCapacity() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Max_Plant_Count__c = 10, CAMPX__Total_Plant_Count__c = 90);
        Test.startTest();
        insert(garden);
        Test.stopTest();
        CAMPX__Garden__c query = [SELECT Id, CAMPX__Capacity__c, CAMPX__Status__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        Assert.isTrue(query.CAMPX__Capacity__c > 100);
        Assert.areNotEqual(garden.CAMPX__Status__c, query.CAMPX__Status__c);
    }

    @isTest
    static void setStatus_HealthBelowSeventy() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            CAMPX__Total_Plant_Count__c = 10, 
            CAMPX__Total_Unhealthy_Plant_Count__c = 0, 
            CAMPX__Max_Plant_Count__c = 10,
            CAMPX__Minimum_Plant_Count__c = 1);
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Health_Index__c, CAMPX__Status__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        Assert.areEqual(100, beforeUpdate.CAMPX__Health_Index__c);
        garden.CAMPX__Total_Unhealthy_Plant_Count__c = 9;
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Health_Index__c, CAMPX__Status__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id 
                                        LIMIT 1];                         
        Assert.areEqual(10, afterUpdate.CAMPX__Health_Index__c);
        Assert.areNotEqual(beforeUpdate.CAMPX__Status__c, afterUpdate.CAMPX__Status__c);
    }

    @isTest
    static void setStatus_TotalBelowMinPlantCount() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            CAMPX__Total_Plant_Count__c = 10, 
            CAMPX__Total_Unhealthy_Plant_Count__c = 0, 
            CAMPX__Max_Plant_Count__c = 10,
            CAMPX__Minimum_Plant_Count__c = 1);
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Health_Index__c, CAMPX__Status__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        garden.CAMPX__Minimum_Plant_Count__c = 12;
        garden.CAMPX__Max_Plant_Count__c = 100;
        
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Health_Index__c, CAMPX__Status__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id 
                                        LIMIT 1];                         
        Assert.areNotEqual(beforeUpdate.CAMPX__Status__c, afterUpdate.CAMPX__Status__c);
    }

    @isTest
    static void setStatus_SkipPermClose() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            CAMPX__Total_Plant_Count__c = 10, 
            CAMPX__Total_Unhealthy_Plant_Count__c = 0, 
            CAMPX__Max_Plant_Count__c = 10,
            CAMPX__Minimum_Plant_Count__c = 1);
        insert(garden);
        CAMPX__Garden__c beforeUpdate = [SELECT Id, CAMPX__Health_Index__c, CAMPX__Status__c
                                         FROM CAMPX__Garden__c 
                                         WHERE Id = :garden.Id 
                                         LIMIT 1];  
        garden.CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.PermanentClosure);
        Test.startTest();
        update garden;
        Test.stopTest();
        CAMPX__Garden__c afterUpdate = [SELECT Id, CAMPX__Health_Index__c, CAMPX__Status__c
                                        FROM CAMPX__Garden__c 
                                        WHERE Id = :garden.Id 
                                        LIMIT 1];                         
        Assert.areNotEqual(beforeUpdate.CAMPX__Status__c, afterUpdate.CAMPX__Status__c);
    }

     @IsTest
    static void testNegativeValues_AddErrors() {
        CAMPX__Garden__c g = new CAMPX__Garden__c(
            CAMPX__Total_Plant_Count__c = -1,
            CAMPX__Total_Unhealthy_Plant_Count__c = -2,
            CAMPX__Minimum_Plant_Count__c = -3,
            CAMPX__Max_Plant_Count__c = -1
        );

        Test.startTest();
        Database.SaveResult sr = Database.insert(g, false);
        Test.stopTest();

        Assert.isFalse(sr.isSuccess(), 'Record should NOT insert because of negative values');
        Assert.isTrue(sr.getErrors().size() == 1,'Only one error is expected because addError halts further DML on this record');
        Assert.isTrue(sr.getErrors()[0].getMessage().contains('Plant Count fields must be greater than or equal to zero'), 'Error message mismatch');
    }

    @IsTest
    static void testPositiveValues_NoErrors() {
        CAMPX__Garden__c g = new CAMPX__Garden__c(
            CAMPX__Total_Plant_Count__c = 5,
            CAMPX__Total_Unhealthy_Plant_Count__c = 1,
            CAMPX__Minimum_Plant_Count__c = 0,
            CAMPX__Max_Plant_Count__c = 10
        );

        Test.startTest();
        insert g;
        Test.stopTest();

        Assert.areNotEqual(null, g.Id, 'Record should insert successfully');
    }

}