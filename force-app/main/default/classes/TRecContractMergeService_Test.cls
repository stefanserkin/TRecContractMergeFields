@IsTest
private class TRecContractMergeService_Test {
    
    @TestSetup
    static void makeData() {
        Account testAccount = new Account(Name = 'Rey Ordonez Test Account');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'Rey', LastName = 'Ordonez', AccountId = testAccount.Id);
        insert testContact;

        TREX1__Contract_and_Form__c contract = new TREX1__Contract_and_Form__c(
            Name = 'Test Contract',
            TREX1__Waiver_Text__c = 'Hello {!Name}, your account is {!TREX1__Account__r.Name} and contact account is {!TREX1__Contact__r.Account.Name}.',
            TREX1__Account__c = testAccount.Id,
            TREX1__Contact__c = testContact.Id,
            TREX1__Contract_Expiry_Policy__c = 'Always Required',
            TREX1__Valid_For__c = 'Account',
            TREX1__Type__c = 'Waiver Form',
            TREX1__Status__c = 'Draft'
        );
        insert contract;
    }

    @IsTest
    static void testGetMergeFieldsFromString() {
        String input = 'Hello {!Name}, your contract ID is {!Id}';
        Set<String> expectedFields = new Set<String>{'Name', 'Id'};
        
        Test.startTest();
        Set<String> actualFields = TRecContractMergeService.getMergeFieldsFromString(input);
        Test.stopTest();
        
        System.Assert.areEqual(expectedFields, actualFields, 'Merge fields should match expected values.');
    }

    @IsTest
    static void testReplaceMergeFieldsWithValues() {
        TREX1__Contract_and_Form__c contract = [SELECT Name, TREX1__Waiver_Text__c FROM TREX1__Contract_and_Form__c LIMIT 1];
        contract.Name = 'Test Contract Name';
        
        Test.startTest();
        String updatedText = TRecContractMergeService.replaceMergeFieldsWithValues(
            'Hello {!Name}, welcome to the system!', 
            contract
        );
        Test.stopTest();
        
        System.Assert.isTrue(updatedText.contains('Test Contract Name'), 'Merge field should be replaced with actual value.');
    }

    @IsTest
    static void testGetFieldValue() {
        TREX1__Contract_and_Form__c contract = [SELECT Name FROM TREX1__Contract_and_Form__c LIMIT 1];

        Test.startTest();
        Object fieldValue = TRecContractMergeService.getFieldValue(contract, 'Name');
        Test.stopTest();

        System.Assert.areEqual(contract.Name, fieldValue, 'Field value should match expected contract name.');
    }

    @IsTest
    static void testGetFieldDescribe() {
        TREX1__Contract_and_Form__c contract = [SELECT Name FROM TREX1__Contract_and_Form__c LIMIT 1];

        Test.startTest();
        Schema.DescribeFieldResult describeResult = TRecContractMergeService.getFieldDescribe(contract, 'Name');
        Test.stopTest();

        System.Assert.areNotEqual(null, describeResult, 'DescribeFieldResult should not be null.');
        System.Assert.areEqual(Schema.DisplayType.STRING, describeResult.getType(), 'Expected Name field to be a STRING.');
    }

    @IsTest
    static void testPopulateMergeFields() {
        List<TREX1__Contract_and_Form__c> contracts = [SELECT Id, TREX1__Waiver_Text__c FROM TREX1__Contract_and_Form__c];

        Test.startTest();
        TRecContractMergeService service = new TRecContractMergeService(contracts);
        List<TREX1__Contract_and_Form__c> updatedContracts = service.populateMergeFields();
        Test.stopTest();

        System.Assert.areNotEqual(null, updatedContracts, 'Returned contract list should not be null.');
        System.Assert.isTrue(updatedContracts.size() > 0, 'At least one contract should be processed.');
    }

    @IsTest
    static void testFormatFieldValue() {
        Schema.DescribeFieldResult dateFieldDescribe = Account.CreatedDate.getDescribe();

        Test.startTest();
        String formattedDate = TRecContractMergeService.formatFieldValue(Date.today(), dateFieldDescribe);
        Test.stopTest();

        System.Assert.areNotEqual('', formattedDate, 'Formatted date should not be empty.');
    }

}
