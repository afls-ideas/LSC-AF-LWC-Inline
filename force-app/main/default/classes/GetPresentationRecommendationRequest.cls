@JsonAccess(serializable='always' deserializable='always')
global class GetPresentationRecommendationRequest {
    @InvocableVariable(label='Topic' description='Optional. The topic, product, or subject the rep asked about (e.g. "efficacy", "dosing", "safety"). Not required — never ask the user for this; call the action immediately, leaving it blank if no topic is named, to recommend the single most recently updated active slide across all presentations.')
    global String topic;
}
