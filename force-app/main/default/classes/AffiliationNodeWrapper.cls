/**
 * One node on the `hcpAffiliationNetworkCLT` graph — either the center HCP
 * or an organization/colleague provider connected to them. Top-level
 * `global` + `@JsonAccess`, matching every other CLT-bound type in this
 * library, even though it only ever nests inside
 * HcpAffiliationNetworkWrapper — nested types must still be top-level
 * global for the `@apexClassType` CLT binding to resolve.
 */
@JsonAccess(serializable='always' deserializable='always')
global class AffiliationNodeWrapper {
    @AuraEnabled global String id;
    @AuraEnabled global String label;
    @AuraEnabled global String nodeType;
    @AuraEnabled global Boolean isCenter;
}
