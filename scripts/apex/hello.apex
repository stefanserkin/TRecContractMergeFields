// Use .apex files to store anonymous Apex.
// You can execute anonymous Apex in VS Code by selecting the
//     apex text and running the command:
//     SFDX: Execute Anonymous Apex with Currently Selected Text
// You can also execute the entire file by running the command:
//     SFDX: Execute Anonymous Apex with Editor Contents

Id contractId = 'a1pcW000008jB17QAE';
List<TREX1__Contract_and_Form__c> contracts = [
    SELECT Id, TREX1__Waiver_Text__c 
      FROM TREX1__Contract_and_Form__c 
     WHERE Id = :contractId
];

TRecContractMergeService service = new TRecContractMergeService(contracts);
List<TREX1__Contract_and_Form__c> updatedContracts = service.populateMergeFields();
System.debug(':::: updated contracts...' );
TREX1__Contract_and_Form__c contract = updatedContracts[0];
System.debug(':::: contract name --> ' + contract.get('Name'));
System.debug(':::: contract account id --> ' + contract.get('TREX1__Account__c'));
System.debug(':::: contract account name --> ' + contract.TREX1__Account__r.Name);
System.debug(contract.TREX1__Waiver_Text__c);

