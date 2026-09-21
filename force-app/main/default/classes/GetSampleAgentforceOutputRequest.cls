@JsonAccess(serializable='always' deserializable='always')
global class GetSampleAgentforceOutputRequest {
    @InvocableVariable(label='Topic' description='What the sample card should mention. Leave blank to use the default sample topic.')
    global String topic;
}
