@JsonAccess(serializable='always' deserializable='always')
global class GetHcpAffiliationNetworkRequest {
    @InvocableVariable(label='Account Name' description='Optional. The HCP the rep asked about. Not required — never ask the user for this; call the action immediately, leaving it blank if no HCP is named, to use the real HCP with the most affiliation records.')
    global String accountName;
}
