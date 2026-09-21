@JsonAccess(serializable='always' deserializable='always')
global class GetCaseEscalationSummaryResult {
    @InvocableVariable(label='Summary' description='The case summary to display in the chat window.')
    global CaseEscalationSummaryWrapper summary;

    @InvocableVariable(label='Output' description='Plain-text confirmation for the planner.')
    global String output;
}
