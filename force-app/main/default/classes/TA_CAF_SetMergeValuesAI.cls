public with sharing class TA_CAF_SetMergeValuesAI implements TriggerAction.AfterInsert {
    
    public void afterInsert(List<TREX1__Contract_and_Form__c> newList) {
        List<TREX1__Contract_and_Form__c> updatedContracts = new TRecContractFieldMerge(newList).populateMergeFields();
        Database.update(updatedContracts, AccessLevel.SYSTEM_MODE);
    }

}