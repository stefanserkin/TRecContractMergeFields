/***********************************************************************
 * @description Substitute field values for their api field names 
 *              in Traction Rec contracts
 * @date 2025
 ***********************************************************************/
public without sharing class TRecContractFieldMerge {

    private List<TREX1__Contract_and_Form__c> contracts;

    public TRecContractFieldMerge(List<TREX1__Contract_and_Form__c> contracts) {
        this.contracts = contracts;
    }

    public List<TREX1__Contract_and_Form__c> populateMergeFields() {
        List<TREX1__Contract_and_Form__c> contractsWithMergeInfo = Database.query( getQuery() );
        return replaceMergeFieldsWithValues(contractsWithMergeInfo);
    }

    private String getQuery() {
        List<String> mergeFields = getMergeFields();
        String query = 'SELECT ' + String.join(mergeFields, ', ') + 
                        ' FROM TREX1__Contract_and_Form__c WHERE Id IN :contracts';
        return String.escapeSingleQuotes(query);
    }

    private List<String> getMergeFields() {
        Set<String> uniqueMergeFields = new Set<String>{ 'TREX1__Waiver_Text__c' };
        for (TREX1__Contract_and_Form__c contract : contracts) {
            uniqueMergeFields.addAll( MergeFieldService.getMergeFieldsFromString(contract.TREX1__Waiver_Text__c) );
        }
        return new List<String>(uniqueMergeFields);
    }

    private List<TREX1__Contract_and_Form__c> replaceMergeFieldsWithValues(List<TREX1__Contract_and_Form__c> contractsWithMergeInfo) {
        for (TREX1__Contract_and_Form__c contract : contractsWithMergeInfo) {
            contract.TREX1__Waiver_Text__c = MergeFieldService.replaceMergeFieldsWithValues(contract.TREX1__Waiver_Text__c, contract);
        }
        return contractsWithMergeInfo;
    }

}