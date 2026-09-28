@JsonAccess(serializable='always' deserializable='always')
global class GetPresentationRecommendationResult {
    @InvocableVariable(label='Recommendation' description='The recommended presentation slide, with its thumbnail, to display in the chat window.')
    global PresentationRecommendationWrapper recommendation;

    @InvocableVariable(label='Summary' description='Plain-text summary of the recommendation for the planner.')
    global String summary;
}
