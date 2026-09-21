/**
 * CLT data type backing the `fieldStockSnapshotCLT` custom Lightning type.
 *
 * Top-level `global` + `@JsonAccess`, `@AuraEnabled global` fields — required
 * for the `@apexClassType` CLT binding to resolve when the type is declared
 * via an Agent Script `complex_data_type_name` output.
 */
@JsonAccess(serializable='always' deserializable='always')
global class FieldStockSnapshotWrapper {
    @AuraEnabled global String productName;
    @AuraEnabled global Integer onHandQty;
    @AuraEnabled global Integer reorderThreshold;
    @AuraEnabled global Boolean isLowStock;
    @AuraEnabled global String lastCountDate;
}
