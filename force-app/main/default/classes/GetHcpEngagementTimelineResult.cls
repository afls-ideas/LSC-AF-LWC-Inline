@JsonAccess(serializable='always' deserializable='always')
global class GetHcpEngagementTimelineResult {
    @InvocableVariable(label='Timeline' description='The engagement timeline to display in the chat window.')
    global HcpEngagementTimelineWrapper timeline;

    @InvocableVariable(label='Summary' description='Plain-text summary of the timeline for the planner.')
    global String summary;
}
