@JsonAccess(serializable='always' deserializable='always')
global class GetFieldStockSnapshotRequest {
    @InvocableVariable(label='Product Name' description='Optional. The product the rep asked about. Not required — never ask the user for this; call the action immediately, leaving it blank if no product is named, to find the single most urgent real active lot across all products.')
    global String productName;
}
