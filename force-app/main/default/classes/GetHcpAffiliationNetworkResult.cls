@JsonAccess(serializable='always' deserializable='always')
global class GetHcpAffiliationNetworkResult {
    @InvocableVariable(label='Network' description='The affiliation network to display in the chat window.')
    global HcpAffiliationNetworkWrapper network;

    @InvocableVariable(label='Summary' description='Plain-text summary of the network for the planner.')
    global String summary;
}
