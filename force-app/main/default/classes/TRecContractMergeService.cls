public with sharing class TRecContractMergeService {

    private List<TREX1__Contract_and_Form__c> contracts;

    public TRecContractMergeService(List<TREX1__Contract_and_Form__c> contracts) {
        this.contracts = contracts;
    }

    public List<TREX1__Contract_and_Form__c> populateMergeFields() {
        return contracts;
    }

}