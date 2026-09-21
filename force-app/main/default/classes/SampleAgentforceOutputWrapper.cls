/**
 * CLT data type backing the `sampleAgentforceOutputCLT` custom Lightning type.
 *
 * Top-level `global` + `@JsonAccess`, `@AuraEnabled global` fields — required
 * for the `@apexClassType` CLT binding to resolve when the type is declared
 * via an Agent Script `complex_data_type_name` output (see docs/LIGHTNING_TYPES.md
 * in the Power_Agent_ADLC sibling project for the proven convention this follows).
 */
@JsonAccess(serializable='always' deserializable='always')
global class SampleAgentforceOutputWrapper {
    @AuraEnabled global String title;
    @AuraEnabled global String message;
    @AuraEnabled global List<String> items;
}
