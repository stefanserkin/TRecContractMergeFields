public with sharing class TRecContractMergeService {

    private static final String MERGE_FIELD_REGEX = '\\{!.+?\\}';

    private List<TREX1__Contract_and_Form__c> contracts;

    public TRecContractMergeService(List<TREX1__Contract_and_Form__c> contracts) {
        this.contracts = contracts;
    }

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
        
        System.debug(':::: query --> ' + query);

        List<TREX1__Contract_and_Form__c> contractsWithMergeInfo = Database.query( String.escapeSingleQuotes(query) );

        System.debug(':::: contracts --> ' + contractsWithMergeInfo);


        for (TREX1__Contract_and_Form__c contract : contractsWithMergeInfo) {
            contract.TREX1__Waiver_Text__c = replaceMergeFieldsWithValues(contract.TREX1__Waiver_Text__c, contract);
        }
        System.debug(':::: contracts --> ' + contractsWithMergeInfo);
        return contractsWithMergeInfo;
    }

    public static String doMergingStuff(String input) {

        Set<String> mergeFields = getMergeFieldsFromString(input);
        System.debug('mergeFields: ' + mergeFields);

        return input;
    }

    /****************************************************
     * Returns a set of field api names for merge fields in the input
     * @param String String containing merge fields
     ****************************************************/
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
    private static String replaceMergeFieldsWithValues(String input, SObject obj) {
        String result = input;
        Pattern p = Pattern.compile(MERGE_FIELD_REGEX);
        Matcher m = p.matcher(result);

        while(m.find()) {
            String fieldApiPath = m.group().substring(2, m.group().length() - 1);
            System.debug('::: fieldApiPath --> ' + fieldApiPath);

            Object fieldValue = getFieldValue(obj, fieldApiPath);
            System.debug('::: fieldValue --> ' + fieldValue);
            Schema.DescribeFieldResult fieldDescribe = getFieldDescribe(obj, fieldApiPath);
            System.debug('::: field describe --> ' + fieldDescribe);
            String formattedValue = formatFieldValue(fieldValue, fieldDescribe);
            System.debug('::: formattedValue --> ' + formattedValue);
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
        if (record == null || String.isEmpty(fieldPath)) {
            return null;
        }

        List<String> fieldParts = fieldPath.split('\\.');
        SObject currentRecord = record;

        // Iterate through field path parts
        for (Integer i = 0; i < fieldParts.size(); i++) {
            String field = fieldParts[i];

            // If it's the last field in the path, return the field value
            if (i == fieldParts.size() - 1) {
                return currentRecord.get(field);
            }

            // Otherwise, traverse the relationship
            currentRecord = currentRecord.getSObject(field);
            if (currentRecord == null) {
                return null;
            }
        }
        return null;
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
        if (record == null || String.isEmpty(fieldPath)) {
            return null;
        }

        List<String> fieldParts = fieldPath.split('\\.');
        Schema.SObjectType currentSObjectType = record.getSObjectType();

        for (Integer i = 0; i < fieldParts.size(); i++) {
            String fieldName = fieldParts[i];

            // Get the field map for the current SObject
            Map<String, Schema.SObjectField> fieldMap = currentSObjectType.getDescribe().fields.getMap();

            // Handle relationship field resolution
            if (!fieldMap.containsKey(fieldName)) {
                // If the field is a relationship, its actual field name may be different
                if (fieldName.endsWith('__r')) {
                    String lookupFieldName = fieldName.replace('__r', '__c'); // Convert custom relationship field
                    if (fieldMap.containsKey(lookupFieldName)) {
                        fieldName = lookupFieldName;
                    } else {
                        return null; // Relationship field not found
                    }
                } else {
                    // Check for standard lookup fields (e.g., Account -> AccountId)
                    for (String potentialField : fieldMap.keySet()) {
                        if (potentialField.toLowerCase().startsWith(fieldName.toLowerCase()) && potentialField.endsWith('Id')) {
                            fieldName = potentialField;
                            break;
                        }
                    }
                }
            }

            Schema.SObjectField field = fieldMap.get(fieldName);
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            // If this is the last field in the path, return its describe result
            if (i == fieldParts.size() - 1) {
                return fieldDescribe;
            }

            // If it's a relationship, update currentSObjectType to the related SObject type
            if (fieldDescribe.getType() == Schema.DisplayType.REFERENCE) {
                List<Schema.SObjectType> referenceTo = fieldDescribe.getReferenceTo();
                if (!referenceTo.isEmpty()) {
                    currentSObjectType = referenceTo[0]; // Assume single reference type
                } else {
                    return null; // If no reference type is found, return null
                }
            } else {
                return null; // If a non-relationship field appears before the last, return null
            }
        }

        return null; // Fallback in case of an unexpected issue
    }

    /****************************************************
     * Format field values based on data type
     * @param Object The field value
     * @param Schema.DescribeFieldResult field describe for the provided field
     * @return String Formatted field value
     ****************************************************/
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