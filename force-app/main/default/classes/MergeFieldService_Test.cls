@IsTest
private class MergeFieldService_Test {

    @IsTest
    static void testGetMergeFieldsFromString() {
        String input = 'Hello {!Name}, your contract ID is {!Id}';
        Set<String> expectedFields = new Set<String>{'Name', 'Id'};
        
        Test.startTest();
        Set<String> actualFields = MergeFieldService.getMergeFieldsFromString(input);
        Test.stopTest();
        
        System.Assert.areEqual(expectedFields, actualFields, 'Merge fields should match expected values.');
    }

    @IsTest
    static void testReplaceMergeFieldsWithValues() {
        String accountName = 'Test Account for Merges';
        Account acc = new Account(Name = accountName);

        String input = 'Hello {!Name}!';

        Test.startTest();
        String result = MergeFieldService.replaceMergeFieldsWithValues(input, acc);
        Test.stopTest();

        System.Assert.isTrue(result.contains(accountName), 'Merge field should be replaced with actual value.');
    }

    @IsTest
    static void testReplaceParentMergeFieldsWithValues() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('HH_Account').getRecordTypeId();
        Account acc = new Account(Name = 'Test Account for Merges', RecordTypeId = recordTypeId);
        insert acc;

        Contact ct = new Contact(AccountId = acc.Id, FirstName = 'Testeroo', LastName = 'Merges');
        insert ct;

        Contact contactWithMergeFields = [SELECT Id, Account.Name FROM Contact WHERE Id = :ct.Id LIMIT 1];

        String input = 'Hello {!Account.Name}!';

        Test.startTest();
        String result = MergeFieldService.replaceMergeFieldsWithValues(input, contactWithMergeFields);
        Test.stopTest();

        System.Assert.isTrue(
            result.contains(contactWithMergeFields.Account.Name), 
            'Merge field should be replaced with actual value.'
        );
    }

    @IsTest
    static void testFormatFieldValue() {
        Schema.DescribeFieldResult dateFieldDescribe = Account.CreatedDate.getDescribe();

        Test.startTest();
        String formattedDate = MergeFieldService.formatFieldValue(Date.today(), dateFieldDescribe);
        Test.stopTest();

        System.Assert.isnotNull(formattedDate, 'Formatted date should not be empty');
    }

    @IsTest
    static void testFormatNullValue() {
        Schema.DescribeFieldResult annualRevenueFieldDescribe = Account.AnnualRevenue.getDescribe();

        Test.startTest();
        String formattedRevenue = MergeFieldService.formatFieldValue(null, annualRevenueFieldDescribe);
        Test.stopTest();

        System.Assert.areEqual('', formattedRevenue, 'Formatted revenue should be an empty string');
    }

    @IsTest
    static void testFormatCurrencyFieldValue() {
        Schema.DescribeFieldResult annualRevenueFieldDescribe = Account.AnnualRevenue.getDescribe();

        Test.startTest();
        String formattedRevenue = MergeFieldService.formatFieldValue(100.00, annualRevenueFieldDescribe);
        Test.stopTest();

        System.Assert.isNotNull(formattedRevenue, 'Formatted revenue should not be null');
    }
    
}