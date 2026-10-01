/**
 * One edge on the `hcpAffiliationNetworkCLT` graph, connecting a provider
 * (center or colleague) to an organization. Top-level `global` +
 * `@JsonAccess`, matching every other CLT-bound type in this library.
 */
@JsonAccess(serializable='always' deserializable='always')
global class AffiliationEdgeWrapper {
    @AuraEnabled global String sourceId;
    @AuraEnabled global String targetId;
    @AuraEnabled global String affiliationType;
    @AuraEnabled global Boolean isPrimary;
    @AuraEnabled global String role;
}
