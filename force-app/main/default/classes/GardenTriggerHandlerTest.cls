@isTest
private class GardenTriggerHandlerTest {

    @isTest
    static void initalizeTest_NoUserInput() {
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
      CAMPX__Garden__c expected = [SELECT Id, CAMPX__Status__c, CAMPX__Max_Plant_Count__c, CAMPX__Minimum_Plant_Count__c, CAMPX__Total_Plant_Count__c, CAMPX__Total_Unhealthy_Plant_Count__c 
                                   FROM CAMPX__Garden__c WHERE Id = :garden.Id LIMIT 1];                         
      Assert.areEqual('Operational', expected.CAMPX__Status__c);
      Assert.areEqual(1000, expected.CAMPX__Max_Plant_Count__c);
      Assert.areEqual(5, expected.CAMPX__Minimum_Plant_Count__c);
      Assert.areEqual(10, expected.CAMPX__Total_Plant_Count__c);
      Assert.areEqual(0, expected.CAMPX__Total_Unhealthy_Plant_Count__c);
    }
}