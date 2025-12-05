@isTest
private class PlantTriggerHandlerTest {

    @isTest
    static void intializationTest_Defaults() {
        CAMPX__Plant__c plant = new CAMPX__Plant__c();
        Test.startTest();
        insert plant;
        Test.stopTest();
        CAMPX__Plant__c actual = [SELECT Id, CAMPX__Soil_Type__c, CAMPX__Water__c, CAMPX__Sunlight__c FROM CAMPX__Plant__c WHERE Id = :plant.Id LIMIT 1];
        Assert.areEqual('All Purpose Potting Soil', actual.CAMPX__Soil_Type__c);
        Assert.areEqual('Once Weekly', actual.CAMPX__Water__c);
        Assert.areEqual('Partial Sun', actual.CAMPX__Sunlight__c);
    }

    @isTest
    static void intializationTest_UserInput() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Sun_Exposure__c = 'Full Sun');
        insert garden;
        CAMPX__Plant__c plant = new CAMPX__Plant__c(CAMPX__Garden__c = garden.Id, CAMPX__Soil_Type__c = 'Sand', CAMPX__Water__c = 'Daily');
        Test.startTest();
        insert plant;
        Test.stopTest();
        CAMPX__Plant__c actual = [SELECT Id, CAMPX__Soil_Type__c, CAMPX__Water__c, CAMPX__Sunlight__c FROM CAMPX__Plant__c WHERE Id = :plant.Id LIMIT 1];
        Assert.areEqual('Sand', actual.CAMPX__Soil_Type__c);
        Assert.areEqual('Daily', actual.CAMPX__Water__c);
        Assert.areEqual('Full Sun', actual.CAMPX__Sunlight__c);
    }

    @isTest
    static void aggregateTotalPlantCount_Insert() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c();
        insert garden;
        List<CAMPX__Plant__c> plants = new List<CAMPX__Plant__c> { 
            new CAMPX__Plant__c(CAMPX__Garden__c = garden.Id),
            new CAMPX__Plant__c(CAMPX__Garden__c = garden.Id) 
        };

        CAMPX__Plant__c plant1 = plants[0];
        CAMPX__Plant__c plant2 = plants[1];
        insert plants;

        CAMPX__Plant__c plant3 = new CAMPX__Plant__c(CAMPX__Garden__c = garden.Id);
        Test.startTest();
        insert plant3;
        Test.stopTest();
        Assert.areEqual(3, [SELECT CAMPX__Total_Plant_Count__c FROM CAMPX__Garden__c WHERE Id = :garden.Id].CAMPX__Total_Plant_Count__c);
    }

    @isTest
    static void aggregateTotalPlantCount_Delete() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c();
        insert garden;
        List<CAMPX__Plant__c> plants = new List<CAMPX__Plant__c> { 
            new CAMPX__Plant__c(CAMPX__Garden__c = garden.Id),
            new CAMPX__Plant__c(CAMPX__Garden__c = garden.Id) 
        };

        CAMPX__Plant__c plant1 = plants[0];
        CAMPX__Plant__c plant2 = plants[1];
        insert plants;

        Test.startTest();
        delete plant2;
        Test.stopTest();
        Assert.areEqual(1, [SELECT CAMPX__Total_Plant_Count__c FROM CAMPX__Garden__c WHERE Id = :garden.Id].CAMPX__Total_Plant_Count__c);
    }

    @isTest
    static void aggregateTotalPlantCount_Move() {
        List<CAMPX__Garden__c> gardens = new List<CAMPX__Garden__c>{
            new CAMPX__Garden__c(),
            new CAMPX__Garden__c()
        };
        insert gardens;
        CAMPX__Garden__c garden1 = gardens[0];
        CAMPX__Garden__c garden2 = gardens[1];
        List<CAMPX__Plant__c> plants = new List<CAMPX__Plant__c> { 
            new CAMPX__Plant__c(CAMPX__Garden__c = garden1.Id),
            new CAMPX__Plant__c(CAMPX__Garden__c = garden1.Id) 
        };

        CAMPX__Plant__c plant1 = plants[0];
        CAMPX__Plant__c plant2 = plants[1];
        insert plants;

        Assert.areEqual(2, [SELECT CAMPX__Total_Plant_Count__c FROM CAMPX__Garden__c WHERE Id = :garden1.Id].CAMPX__Total_Plant_Count__c);

        plant1.CAMPX__Garden__c = garden2.Id;

        Test.startTest();
        update plant1;
        Test.stopTest();
        Assert.areEqual(1, [SELECT CAMPX__Total_Plant_Count__c FROM CAMPX__Garden__c WHERE Id = :garden1.Id].CAMPX__Total_Plant_Count__c);
        Assert.areEqual(1, [SELECT CAMPX__Total_Plant_Count__c FROM CAMPX__Garden__c WHERE Id = :garden2.Id].CAMPX__Total_Plant_Count__c);
    }

    @isTest
    static void aggregateTotalUnhealthyPlantCount_Insert() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c();
        insert garden;
        List<CAMPX__Plant__c> plants = new List<CAMPX__Plant__c> { 
            new CAMPX__Plant__c(CAMPX__Garden__c = garden.Id, CAMPX__Status__c = 'Healthy'),
            new CAMPX__Plant__c(CAMPX__Garden__c = garden.Id, CAMPX__Status__c = 'Sick') 
        };

        CAMPX__Plant__c plant1 = plants[0];
        CAMPX__Plant__c plant2 = plants[1];
        insert plants;

        CAMPX__Plant__c plant3 = new CAMPX__Plant__c(CAMPX__Garden__c = garden.Id, CAMPX__Status__c = 'Wilting');
        Test.startTest();
        insert plant3;
        Test.stopTest();
        Assert.areEqual(2, [SELECT CAMPX__Total_Unhealthy_Plant_Count__c FROM CAMPX__Garden__c WHERE Id = :garden.Id].CAMPX__Total_Unhealthy_Plant_Count__c);
    }

    @isTest
    static void aggregateTotalUnhealthyPlantCount_Update() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c();
        insert garden;
        List<CAMPX__Plant__c> plants = new List<CAMPX__Plant__c> { 
            new CAMPX__Plant__c(CAMPX__Garden__c = garden.Id, CAMPX__Status__c = 'Healthy'),
            new CAMPX__Plant__c(CAMPX__Garden__c = garden.Id, CAMPX__Status__c = 'Sick') 
        };

        CAMPX__Plant__c plant1 = plants[0];
        CAMPX__Plant__c plant2 = plants[1];
        insert plants;

        plant1.CAMPX__Status__c = 'Wilting';
        Test.startTest();
        update plant1;
        Test.stopTest();
        Assert.areEqual(2, [SELECT CAMPX__Total_Unhealthy_Plant_Count__c FROM CAMPX__Garden__c WHERE Id = :garden.Id].CAMPX__Total_Unhealthy_Plant_Count__c);
    }

    @isTest
    static void aggregateTotalUnhealthyPlantCount_Delete() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c();
        insert garden;
        List<CAMPX__Plant__c> plants = new List<CAMPX__Plant__c> { 
            new CAMPX__Plant__c(CAMPX__Garden__c = garden.Id, CAMPX__Status__c = 'Healthy'),
            new CAMPX__Plant__c(CAMPX__Garden__c = garden.Id, CAMPX__Status__c = 'Sick') 
        };

        CAMPX__Plant__c plant1 = plants[0];
        CAMPX__Plant__c plant2 = plants[1];
        insert plants;

        Test.startTest();
        delete plant2;
        Test.stopTest();
        Assert.areEqual(0, [SELECT CAMPX__Total_Unhealthy_Plant_Count__c FROM CAMPX__Garden__c WHERE Id = :garden.Id].CAMPX__Total_Unhealthy_Plant_Count__c);
    }

    @isTest
    static void aggregateTotalUnhealthyPlantCount_Move() {
        List<CAMPX__Garden__c> gardens = new List<CAMPX__Garden__c>{
            new CAMPX__Garden__c(),
            new CAMPX__Garden__c()
        };
        insert gardens;
        CAMPX__Garden__c garden1 = gardens[0];
        CAMPX__Garden__c garden2 = gardens[1];
        List<CAMPX__Plant__c> plants = new List<CAMPX__Plant__c> { 
            new CAMPX__Plant__c(CAMPX__Garden__c = garden1.Id, CAMPX__Status__c = 'Deceased'),
            new CAMPX__Plant__c(CAMPX__Garden__c = garden1.Id, CAMPX__Status__c = 'Sick') 
        };

        CAMPX__Plant__c plant1 = plants[0];
        CAMPX__Plant__c plant2 = plants[1];
        insert plants;

        Assert.areEqual(2, [SELECT CAMPX__Total_Unhealthy_Plant_Count__c FROM CAMPX__Garden__c WHERE Id = :garden1.Id].CAMPX__Total_Unhealthy_Plant_Count__c);

        plant1.CAMPX__Garden__c = garden2.Id;

        Test.startTest();
        update plant1;
        Test.stopTest();
        Assert.areEqual(1, [SELECT CAMPX__Total_Unhealthy_Plant_Count__c FROM CAMPX__Garden__c WHERE Id = :garden1.Id].CAMPX__Total_Unhealthy_Plant_Count__c);
        Assert.areEqual(1, [SELECT CAMPX__Total_Unhealthy_Plant_Count__c FROM CAMPX__Garden__c WHERE Id = :garden2.Id].CAMPX__Total_Unhealthy_Plant_Count__c);
    }

    // -------------------------------------------------------------
    // 1. Creating a plant in a permanently closed garden → ERROR
    // -------------------------------------------------------------
    @isTest
    static void testCreatePlantClosedGardenThrowsError() {
        CAMPX__Garden__c closedGarden = new CAMPX__Garden__c(CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.PermanentClosure));
        insert closedGarden;

        CAMPX__Plant__c p = new CAMPX__Plant__c(CAMPX__Garden__c = closedGarden.Id);

        Test.startTest();
        Database.SaveResult sr = Database.insert(p, false);
        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Expected error when creating plant in a permanently closed garden');
        System.assert(sr.getErrors()[0].getMessage().contains('permanently closed'));
    }

    // -------------------------------------------------------------
    // 2. Updating an existing plant *into* a permanently closed garden → ERROR
    // -------------------------------------------------------------
    @isTest
    static void testUpdatePlantToClosedGardenThrowsError() {
        List<CAMPX__Garden__c> gardens = new List<CAMPX__Garden__c>{
            new CAMPX__Garden__c(CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.Operational)),
            new CAMPX__Garden__c(CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.PermanentClosure))
        };
        insert gardens;
        CAMPX__Garden__c opGarden = gardens[0];
        CAMPX__Garden__c closedGarden = gardens[1];

        Assert.areEqual(GardenConstants.getStatusLabel(GardenConstants.Status.Operational), opGarden.CAMPX__Status__c);
        Assert.areEqual(GardenConstants.getStatusLabel(GardenConstants.Status.PermanentClosure), closedGarden.CAMPX__Status__c);
        
        CAMPX__Plant__c p = new CAMPX__Plant__c(CAMPX__Garden__c = opGarden.Id);
        insert p;

        p.CAMPX__Garden__c = closedGarden.Id;

        Test.startTest();
        Database.SaveResult sr = Database.update(p, false);
        Test.stopTest();

        System.assert(!sr.isSuccess(), 'Expected error when updating plant to a permanently closed garden');
        System.assert(sr.getErrors()[0].getMessage().contains('permanently closed'));
    }

    // -------------------------------------------------------------
    // 3. Updating an existing plant to a *temporarily* closed garden → NO ERROR
    // -------------------------------------------------------------
    @isTest
    static void testUpdatePlantToTempClosedGardenAllowed() {
        List<CAMPX__Garden__c> gardens = new List<CAMPX__Garden__c>{
           new CAMPX__Garden__c(CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.Operational)),
           new CAMPX__Garden__c(CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.TemporaryClosure)),
           new CAMPX__Garden__c(CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.PermanentClosure))
        };
        insert gardens;
        CAMPX__Garden__c opGarden = gardens[0];
        CAMPX__Garden__c tempGarden = gardens[1];
        CAMPX__Garden__c closedGarden = gardens[2];

        // Create plant initially in operational garden
        CAMPX__Plant__c p = new CAMPX__Plant__c(CAMPX__Garden__c = opGarden.Id);
        insert p;

        // Move to temporary closure garden
        p.CAMPX__Garden__c = tempGarden.Id;

        Test.startTest();
        Database.SaveResult sr = Database.update(p, false);
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Updating to a temporarily closed garden should be allowed.');
    }

    // -------------------------------------------------------------
    // 4. Creating a plant in a temporarily closed garden → NO ERROR
    // -------------------------------------------------------------
    @isTest
    static void testCreatePlantInTempClosedGardenAllowed() {
        List<CAMPX__Garden__c> gardens = new List<CAMPX__Garden__c>{
            new CAMPX__Garden__c(CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.Operational)),
            new CAMPX__Garden__c(CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.TemporaryClosure)),
            new CAMPX__Garden__c(CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.PermanentClosure))
        };
        insert gardens;
        CAMPX__Garden__c opGarden = gardens[0];
        CAMPX__Garden__c tempGarden = gardens[1];
        CAMPX__Garden__c closedGarden = gardens[2];

        CAMPX__Plant__c p = new CAMPX__Plant__c(CAMPX__Garden__c = tempGarden.Id);

        Test.startTest();
        Database.SaveResult sr = Database.insert(p, false);
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Creating plant in temporarily closed garden should be allowed.');
    }

    // -------------------------------------------------------------
    // 5. Creating a plant in an operational garden → NO ERROR
    // -------------------------------------------------------------
    @isTest
    static void testCreatePlantOperationalGardenAllowed() {
        List<CAMPX__Garden__c> gardens = new List<CAMPX__Garden__c>{
            new CAMPX__Garden__c(CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.Operational)),
            new CAMPX__Garden__c(CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.TemporaryClosure)),
            new CAMPX__Garden__c(CAMPX__Status__c = GardenConstants.getStatusLabel(GardenConstants.Status.PermanentClosure))
        };
        insert gardens;
        CAMPX__Garden__c opGarden = gardens[0];
        CAMPX__Garden__c tempGarden = gardens[1];
        CAMPX__Garden__c closedGarden = gardens[2];

        CAMPX__Plant__c p = new CAMPX__Plant__c(CAMPX__Garden__c = opGarden.Id);

        Test.startTest();
        Database.SaveResult sr = Database.insert(p, false);
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Creating plant in operational garden should be allowed.');
    }


}