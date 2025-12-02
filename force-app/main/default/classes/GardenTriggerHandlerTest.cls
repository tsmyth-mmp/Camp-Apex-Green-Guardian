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
        Assert.areEqual('Awaiting Resources', expected.CAMPX__Status__c);
        Assert.areEqual(100, expected.CAMPX__Max_Plant_Count__c);
        Assert.areEqual(1, expected.CAMPX__Minimum_Plant_Count__c);
        Assert.areEqual(0, expected.CAMPX__Total_Plant_Count__c);
        Assert.areEqual(0, expected.CAMPX__Total_Unhealthy_Plant_Count__c);
    }

    @isTest
    static void initalizeTest_UserInput() {
      CAMPX__Garden__c garden = new CAMPX__Garden__c(
          CAMPX__Status__c = 'Operational',
          CAMPX__Max_Plant_Count__c = 1000,
          CAMPX__Minimum_Plant_Count__c = 5,
          CAMPX__Total_Plant_Count__c = 10
      );
      Test.startTest();
      insert(garden);
      Test.stopTest();
      CAMPX__Garden__c actual = [SELECT Id, CAMPX__Status__c, CAMPX__Max_Plant_Count__c, CAMPX__Minimum_Plant_Count__c, CAMPX__Total_Plant_Count__c, CAMPX__Total_Unhealthy_Plant_Count__c 
                                   FROM CAMPX__Garden__c WHERE Id = :garden.Id LIMIT 1];                         
      Assert.areEqual('Operational', actual.CAMPX__Status__c);
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
        User u1 = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        User u2;
        
        System.runAs(u1) {
            Profile p = [
                SELECT Id
                FROM Profile
                WHERE Name = 'Standard User'
                LIMIT 1
            ];

            u2 = new User(
                Alias = 'tuser',
                Email = 'testuser+' + System.currentTimeMillis() + '@example.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Test',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'America/Los_Angeles',
                Username = 'testuser+' + System.currentTimeMillis() + '@example.com',
                UserRoleId = [SELECT Id FROM UserRole LIMIT 1].Id
            );
            insert u2;
        }

        CAMPX__Garden__c garden = new CAMPX__Garden__c(
            CAMPX__Manager__c = u1.Id
        );
        insert garden;

        garden.CAMPX__Manager__c = u2.Id;

        Test.startTest();
        update garden;
        Test.stopTest();

        CAMPX__Garden__c insertedGarden = [
            SELECT Id, CAMPX__Manager__c
            FROM CAMPX__Garden__c
            WHERE Id = :garden.Id
            LIMIT 1
        ];

        List<Task> tasks = [
            SELECT Id, WhatId, Subject, OwnerId, Status
            FROM Task
            WHERE WhatId = :insertedGarden.Id
        ];

        System.assertEquals(1, tasks.size());
        System.assertEquals(insertedGarden.Id, tasks[0].WhatId);
        System.assertEquals(insertedGarden.CAMPX__Manager__c, tasks[0].OwnerId);
        System.assertEquals('Acquire Plants', tasks[0].Subject);
        System.assertNotEquals('Completed', tasks[0].Status);
    }

}