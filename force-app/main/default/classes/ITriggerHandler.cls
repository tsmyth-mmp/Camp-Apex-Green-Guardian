public interface ITriggerHandler {
    void beforeInsert(List<SObject> newRecords);
    void beforeUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<Id, SObject> oldMap, Map<Id, SObject> newMap);
    void beforeDelete(List<SObject> oldRecords, Map<Id, SObject> oldMap);
    void afterInsert(List<SObject> newRecords, Map<Id, SObject> newRecordMap);
    void afterUpdate(List<SObject> oldRecords, List<SObject> newRecords, Map<Id, SObject> oldMap, Map<Id, SObject> newMap);
    // void afterDelete(List<SObject> oldRecords, Map<Id, SObject> oldMap);
    // void afterUndelete(List<SObject> newRecords, Map<Id, SObject> newRecordMap);
}