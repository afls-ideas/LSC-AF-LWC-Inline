@JsonAccess(serializable='always' deserializable='always')
global class GetSignatureCaptureRequest {
    @InvocableVariable(label='Case Number' description='Optional. The case number or subject keyword the rep named. Not required — never ask the user for this; call the action immediately, leaving it blank if no case is named, to find the single most recently opened case that is not closed.')
    global String caseNumber;
}
