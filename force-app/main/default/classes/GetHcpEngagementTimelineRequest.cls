@JsonAccess(serializable='always' deserializable='always')
global class GetHcpEngagementTimelineRequest {
    @InvocableVariable(label='Account Name' description='Optional. The HCP/account the rep asked about. Not required — never ask the user for this and never skip calling this action for lacking it; call the action immediately, leaving it blank if no account is named, to use the real account with the most engagement history.')
    global String accountName;
}
