/**
 * CLT data type backing the `hcpEngagementTimelineCLT` custom Lightning type.
 *
 * Top-level `global` + `@JsonAccess`, `@AuraEnabled global` fields — required
 * for the `@apexClassType` CLT binding to resolve when the type is declared
 * via an Agent Script `complex_data_type_name` output.
 */
@JsonAccess(serializable='always' deserializable='always')
global class HcpEngagementTimelineWrapper {
    @AuraEnabled global String accountName;
    @AuraEnabled global String headline;
    @AuraEnabled global List<HcpEngagementEventWrapper> events;
}
