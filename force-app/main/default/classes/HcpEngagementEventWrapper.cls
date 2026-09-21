/**
 * One event on the `hcpEngagementTimelineCLT` timeline. Top-level `global` +
 * `@JsonAccess`, matching every other CLT-bound type in this library, even
 * though it only ever nests inside HcpEngagementTimelineWrapper — nested
 * types must still be top-level global for the `@apexClassType` CLT binding
 * to resolve.
 */
@JsonAccess(serializable='always' deserializable='always')
global class HcpEngagementEventWrapper {
    @AuraEnabled global String eventDate;
    @AuraEnabled global String track;
    @AuraEnabled global String title;
    @AuraEnabled global String detail;
    @AuraEnabled global String status;
    @AuraEnabled global String recordUrl;
}
