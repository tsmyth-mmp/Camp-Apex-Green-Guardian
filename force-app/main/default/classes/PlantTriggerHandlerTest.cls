@isTest
private class PlantTriggerHandlerTest {

    @isTest
    static void intializationTest_Defaults() {
        CAMPX__Plant__c plant = new CAMPX__Plant__c();
        Test.startTest();
        insert(plant);
        Test.stopTest();
        CAMPX__Plant__c actual = [SELECT Id, CAMPX__Soil_Type__c, CAMPX__Water__c, CAMPX__Sunlight__c FROM CAMPX__Plant__c WHERE Id = :plant.Id LIMIT 1];
        Assert.areEqual('All Purpose Potting Soil', actual.CAMPX__Soil_Type__c);
        Assert.areEqual('Once Weekly', actual.CAMPX__Water__c);
        Assert.areEqual('Partial Sun', actual.CAMPX__Sunlight__c);
    }

    @isTest
    static void intializationTest_UserInput() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c(CAMPX__Sun_Exposure__c = 'Full Sun');
        insert(garden);
        CAMPX__Plant__c plant = new CAMPX__Plant__c(CAMPX__Garden__c = garden.Id, CAMPX__Soil_Type__c = 'Sand', CAMPX__Water__c = 'Daily');
        Test.startTest();
        insert(plant);
        Test.stopTest();
        CAMPX__Plant__c actual = [SELECT Id, CAMPX__Soil_Type__c, CAMPX__Water__c, CAMPX__Sunlight__c FROM CAMPX__Plant__c WHERE Id = :plant.Id LIMIT 1];
        Assert.areEqual('Sand', actual.CAMPX__Soil_Type__c);
        Assert.areEqual('Daily', actual.CAMPX__Water__c);
        Assert.areEqual('Full Sun', actual.CAMPX__Sunlight__c);
    }

    @isTest
    static void aggregateTotalPlantCount_Insert() {
        CAMPX__Garden__c garden = new CAMPX__Garden__c();
        insert(garden);
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
        insert(garden);
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
}