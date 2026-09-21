@JsonAccess(serializable='always' deserializable='always')
global class GetFieldStockSnapshotResult {
    @InvocableVariable(label='Snapshot' description='The stock snapshot to display in the chat window.')
    global FieldStockSnapshotWrapper snapshot;

    @InvocableVariable(label='Summary' description='Plain-text summary of the snapshot for the planner.')
    global String summary;
}
