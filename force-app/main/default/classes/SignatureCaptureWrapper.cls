/**
 * CLT data type backing the `signatureCaptureCLT` custom Lightning type —
 * a real open Case plus the org's real active priced product catalog, so
 * the card can log what was used, capture a confirmation signature, and
 * generate a draft Order.
 *
 * Top-level `global` + `@JsonAccess`, `@AuraEnabled global` fields — required
 * for the `@apexClassType` CLT binding to resolve when the type is declared
 * via an Agent Script `complex_data_type_name` output.
 */
@JsonAccess(serializable='always' deserializable='always')
global class SignatureCaptureWrapper {
    @AuraEnabled global String caseId;
    @AuraEnabled global String caseNumber;
    @AuraEnabled global String caseSubject;
    @AuraEnabled global String accountId;
    @AuraEnabled global String accountName;
    @AuraEnabled global String pricebookId;
    @AuraEnabled global List<SignatureCaptureLineWrapper> products;
}
