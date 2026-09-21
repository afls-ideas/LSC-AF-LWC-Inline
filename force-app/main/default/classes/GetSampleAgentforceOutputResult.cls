@JsonAccess(serializable='always' deserializable='always')
global class GetSampleAgentforceOutputResult {
    @InvocableVariable(label='Output' description='The sample payload to display in the chat window.')
    global SampleAgentforceOutputWrapper output;

    @InvocableVariable(label='Summary' description='Plain-text summary for the planner.')
    global String summary;
}
