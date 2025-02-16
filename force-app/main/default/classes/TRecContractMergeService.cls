public with sharing class TRecContractMergeService {

    private static final String MERGE_FIELD_REGEX = '\\{!.+?\\}';

    private List<TREX1__Contract_and_Form__c> contracts;

    public TRecContractMergeService(List<TREX1__Contract_and_Form__c> contracts) {
        this.contracts = contracts;
    }

    /****************************************************
     * Replaces merge fields in the waiver text of a list of contract and forms
     ****************************************************/
    public List<TREX1__Contract_and_Form__c> populateMergeFields() {
        Set<String> uniqueMergeFields = new Set<String>{ 'TREX1__Waiver_Text__c' };
        for (TREX1__Contract_and_Form__c contract : contracts) {
            uniqueMergeFields.addAll(
                getMergeFieldsFromString(contract.TREX1__Waiver_Text__c)
            );
        }
        List<String> mergeFields = new List<String>(uniqueMergeFields);

        String query = 'SELECT ' + String.join(mergeFields, ', ') + 
            ' FROM TREX1__Contract_and_Form__c WHERE Id IN :contracts';

        List<TREX1__Contract_and_Form__c> contractsWithMergeInfo = Database.query( String.escapeSingleQuotes(query) );

        for (TREX1__Contract_and_Form__c contract : contractsWithMergeInfo) {
            contract.TREX1__Waiver_Text__c = replaceMergeFieldsWithValues(contract.TREX1__Waiver_Text__c, contract);
        }
        return contractsWithMergeInfo;
    }

    /****************************************************
     * Returns a set of field api names for merge fields in the input
     * @param String String containing merge fields
     ****************************************************/
    @TestVisible
    private static Set<String> getMergeFieldsFromString(String input) {
        Set<String> setMergeFields = new Set<String>();
        Pattern p = Pattern.compile(MERGE_FIELD_REGEX);
        Matcher m = p.matcher(input);
        while(m.find()) {
            String mergeFieldApiName = m.group().substring(2, m.group().length() - 1);
            setMergeFields.add(mergeFieldApiName);
        }
        return setMergeFields;
    }

    /****************************************************
     * Returns the original string with merge fields substituted for their values
     * @param String String containing merge fields to be replaced
     * @param SObject The api name of the sObject type
     ****************************************************/
    @TestVisible
    private static String replaceMergeFieldsWithValues(String input, SObject obj) {
        String result = input;
        Pattern p = Pattern.compile(MERGE_FIELD_REGEX);
        Matcher m = p.matcher(result);

        while(m.find()) {
            String fieldApiPath = m.group().substring(2, m.group().length() - 1);
            Object fieldValue = getFieldValue(obj, fieldApiPath);
            Schema.DescribeFieldResult fieldDescribe = getFieldDescribe(obj, fieldApiPath);
            String formattedValue = formatFieldValue(fieldValue, fieldDescribe);
            result = result.replace(m.group(0), formattedValue);
        }
        return result;
    }

    /**
     * Gets the value of a field from an SObject dynamically, supporting nested relationships.
     * @param record The SObject to retrieve the field value from
     * @param fieldPath The dot-separated field path (e.g., 'TREX1__Registration__r.TREX1__Contact__r.Account.Name')
     * @return The field value as an Object (can be cast to the expected type)
     */
    public static Object getFieldValue(SObject record, String fieldPath) {
        Object result;
        List<String> fieldParts = fieldPath.split('\\.');
        SObject currentRecord = record;

        // Iterate through field path parts
        for (Integer i = 0; i < fieldParts.size(); i++) {
            String field = fieldParts[i];

            // If it's the last field in the path, return the field value
            if (i == fieldParts.size() - 1) {
                result = currentRecord.get(field);
                break;
            }

            // Otherwise, traverse the relationship
            currentRecord = currentRecord.getSObject(field);
        }
        return result;
    }

    /**
     * Gets the DescribeFieldResult for a given field path on an SObject.
     * Supports traversing relationship fields.
     * 
     * @param record The SObject to describe
     * @param fieldPath The dot-separated field path (e.g., 'TREX1__Registration__r.TREX1__Contact__r.Account.Name')
     * @return The Schema.DescribeFieldResult for the last field in the path
     */
    public static Schema.DescribeFieldResult getFieldDescribe(SObject record, String fieldPath) {
        List<String> fieldParts = fieldPath.split('\\.');
        Schema.SObjectType currentSObjectType = record.getSObjectType();

        for (Integer i = 0; i < fieldParts.size(); i++) {
            String fieldName = fieldParts[i];
            Map<String, Schema.SObjectField> fieldMap = currentSObjectType.getDescribe().fields.getMap();

            // Handle relationship field resolution
            if (!fieldMap.containsKey(fieldName)) {
                String lookupFieldName = fieldName.endsWith('__r') ? fieldName.replace('__r', '__c') : fieldName + 'Id';
                if (fieldMap.containsKey(lookupFieldName)) {
                    fieldName = lookupFieldName;
                } else {
                    return null;
                }
            }

            /*
            // Handle relationship field resolution
            if (!fieldMap.containsKey(fieldName)) {
                // Custom fields
                if (fieldName.endsWith('__r')) {
                    String lookupFieldName = fieldName.replace('__r', '__c');
                    if (fieldMap.containsKey(lookupFieldName)) {
                        fieldName = lookupFieldName;
                    } else {
                        return null;
                    }
                } else {
                    // Check for standard lookup fields (e.g., Account -> AccountId)
                    System.debug(':::: ready to evaluate standard field for fieldName --> ' + fieldName);
                    if (fieldMap.containsKey(arg0))

                    
                    for (String potentialField : fieldMap.keySet()) {
                        System.debug('::: checking potential field --> ' + potentialField);
                        if (potentialField.toLowerCase().startsWith(fieldName.toLowerCase()) && potentialField.endsWith('Id')) {
                            System.debug('::: potential field is a match --> ' + potentialField);
                            fieldName = potentialField;
                            break;
                        }
                    }
                        
                }
            }
                */

            Schema.SObjectField field = fieldMap.get(fieldName);
            System.debug('::::::::: field --> ' + field);
            System.debug('::::::::: fieldName --> ' + fieldName);
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            // If this is the last field in the path, return its describe result
            if (i == fieldParts.size() - 1) {
                return fieldDescribe;
            }

            // If it's a relationship, update currentSObjectType to the related SObject type
            if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                List<Schema.SObjectType> referenceTo = fieldDescribe.getReferenceTo();
                if (!referenceTo.isEmpty()) {
                    // Assume single reference type
                    currentSObjectType = referenceTo[0];
                } else {
                    return null;
                }
            } else {
                // If a non-relationship field appears before the last, return null
                return null;
            }
        }

        return null;
    }

    /****************************************************
     * Format field values based on data type
     * @param Object The field value
     * @param Schema.DescribeFieldResult field describe for the provided field
     * @return String Formatted field value
     ****************************************************/
    @TestVisible
    private static String formatFieldValue(Object fieldValue, Schema.DescribeFieldResult fieldDescribe) {
        if (fieldValue == null) return '';

        Schema.DisplayType fieldType = fieldDescribe.getType();

        if (fieldType == Schema.DisplayType.DATE) {
            Date dateValue = (Date) fieldValue;
            return dateValue.format();
        } else if (fieldType == Schema.DisplayType.DATETIME) {
            Datetime datetimeValue = (Datetime) fieldValue;
            return datetimeValue.format();
        } else if (fieldType == Schema.DisplayType.CURRENCY) {
            Decimal currencyValue = (Decimal) fieldValue;
            return '$' + currencyValue.format();
        } else {
            return String.valueOf(fieldValue);
        }
    }

}