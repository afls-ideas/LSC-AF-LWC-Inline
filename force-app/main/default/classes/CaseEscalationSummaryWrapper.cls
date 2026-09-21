/**
 * CLT data type backing the `caseEscalationSummaryCLT` custom Lightning type.
 *
 * Top-level `global` + `@JsonAccess`, `@AuraEnabled global` fields — required
 * for the `@apexClassType` CLT binding to resolve when the type is declared
 * via an Agent Script `complex_data_type_name` output.
 */
@JsonAccess(serializable='always' deserializable='always')
global class CaseEscalationSummaryWrapper {
    @AuraEnabled global String caseId;
    @AuraEnabled global String caseNumber;
    @AuraEnabled global String subject;
    @AuraEnabled global String status;
    @AuraEnabled global String priority;
    @AuraEnabled global String accountName;
    @AuraEnabled global String slaDueDate;
}
