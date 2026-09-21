/**
 * Per-product catalog line backing `signatureCaptureCLT`'s `products` list —
 * one active, priced `PricebookEntry`/`Product2` pair the card can search
 * and add to the usage tally.
 *
 * Top-level `global` + `@JsonAccess`, `@AuraEnabled global` fields — required
 * for the `@apexClassType` CLT binding to resolve when the type is declared
 * via an Agent Script `complex_data_type_name` output.
 */
@JsonAccess(serializable='always' deserializable='always')
global class SignatureCaptureLineWrapper {
    @AuraEnabled global String productId;
    @AuraEnabled global String pricebookEntryId;
    @AuraEnabled global String productName;
    @AuraEnabled global String productCode;
    @AuraEnabled global Decimal unitPrice;
}
