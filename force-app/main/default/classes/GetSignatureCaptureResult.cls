@JsonAccess(serializable='always' deserializable='always')
global class GetSignatureCaptureResult {
    @InvocableVariable(label='Capture' description='The real case + priced product catalog to display in the chat window.')
    global SignatureCaptureWrapper capture;

    @InvocableVariable(label='Summary' description='Plain-text summary of the case, or of the no-data case, for the planner.')
    global String summary;
}
