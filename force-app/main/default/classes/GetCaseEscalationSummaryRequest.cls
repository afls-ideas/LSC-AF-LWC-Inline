@JsonAccess(serializable='always' deserializable='always')
global class GetCaseEscalationSummaryRequest {
    @InvocableVariable(label='Account Name' description='Optional. The account the rep asked about. Not required — never ask the user for this; call the action immediately, leaving it blank if no account is named, to find the single most urgent real open case across all accounts.')
    global String accountName;
}
