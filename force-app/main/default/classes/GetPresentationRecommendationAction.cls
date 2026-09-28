/**
 * GetPresentationRecommendationAction — invocable action for the "LWC
 * Example Library" demo agent. Recommends a REAL active presentation slide
 * for a topic, queried live from Presentation/PresentationLinkedPage/
 * PresentationPage, for display as a Custom Lightning Type renderer
 * (c/presentationRecommendationLWC via presentationRecommendationCLT).
 * No canned data — the best-matching (or most recently updated) active
 * slide is returned, together with its thumbnail image.
 *
 * Data model: a `Presentation` (deck) is sequenced by `PresentationLinkedPage`
 * junction records (DisplayOrder) pointing at `PresentationPage` (slide)
 * records, each of which owns a `ContentDocumentId` (the slide's primary
 * content, often a ZIP-bundled interactive detail aid that Salesforce cannot
 * auto-render a thumbnail for). Slide thumbnails are instead a SEPARATE
 * `ContentDocumentLink` on the same `PresentationPage` pointing at a JPG/PNG
 * "thumbnail" file — that JPG's latest `ContentVersion` is what backs the
 * rendition URL returned here.
 *
 * Top-level `global` + `@JsonAccess`, matching the request/result/type
 * classes, is what lets the `@apexClassType` CLT binding resolve when the
 * type is declared via an Agent Script `complex_data_type_name` output.
 *
 * Created by Peter Yeung on 2026-09-28.
 * Copyright © 2026 Salesforce. All rights reserved.
 */
@JsonAccess(serializable='always' deserializable='always')
global class GetPresentationRecommendationAction {

    private static final String THUMBNAIL_RENDITION = 'THUMB720BY480';

    @InvocableMethod(
        label='Get Presentation Slide Recommendation'
        description='Recommends the rep\'s best-matching real active presentation slide for a topic, queried live from Presentation/PresentationPage, with its thumbnail image, to display as a visual card.')
    global static List<GetPresentationRecommendationResult> get(List<GetPresentationRecommendationRequest> requests) {
        List<GetPresentationRecommendationResult> responses = new List<GetPresentationRecommendationResult>();
        for (GetPresentationRecommendationRequest req : requests) {
            responses.add(buildRecommendation(req.topic));
        }
        return responses;
    }

    private static GetPresentationRecommendationResult buildRecommendation(String topic) {
        String likePattern = String.isNotBlank(topic) ? '%' + topic + '%' : null;

        List<PresentationLinkedPage> links = likePattern == null
            ? [
                SELECT Presentation.Name, PresentationPage.Id, PresentationPage.Name, PresentationPage.PageNumber
                FROM PresentationLinkedPage
                WHERE PresentationPage.Status = 'Active'
                ORDER BY PresentationPage.LastModifiedDate DESC
                LIMIT 1
            ]
            : [
                SELECT Presentation.Name, PresentationPage.Id, PresentationPage.Name, PresentationPage.PageNumber
                FROM PresentationLinkedPage
                WHERE PresentationPage.Status = 'Active'
                AND (Presentation.Name LIKE :likePattern OR PresentationPage.Name LIKE :likePattern)
                ORDER BY PresentationPage.LastModifiedDate DESC
                LIMIT 1
            ];

        GetPresentationRecommendationResult resp = new GetPresentationRecommendationResult();

        if (links.isEmpty()) {
            resp.recommendation = null;
            resp.summary = String.isNotBlank(topic)
                ? 'No active presentation slide was found matching "' + topic + '".'
                : 'No active presentation slides were found in the org.';
            return resp;
        }

        PresentationPage page = links[0].PresentationPage;

        PresentationRecommendationWrapper rec = new PresentationRecommendationWrapper();
        rec.slideName = page.Name;
        rec.presentationName = links[0].Presentation != null ? links[0].Presentation.Name : null;
        rec.pageNumber = page.PageNumber != null ? page.PageNumber.intValue() : null;
        rec.thumbnailUrl = findThumbnailUrl(page.Id);
        rec.matchReason = String.isNotBlank(topic)
            ? 'Matched "' + topic + '" in the presentation or slide title.'
            : 'Most recently updated active slide across all presentations.';

        resp.recommendation = rec;
        resp.summary = 'Recommended slide "' + rec.slideName + '" from "' + rec.presentationName + '" (page '
            + rec.pageNumber + ').';
        return resp;
    }

    private static String findThumbnailUrl(Id presentationPageId) {
        List<ContentDocumentLink> thumbnailLinks = [
            SELECT ContentDocument.LatestPublishedVersionId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :presentationPageId
            AND ContentDocument.FileType IN ('JPG', 'JPEG', 'PNG')
            LIMIT 1
        ];

        if (thumbnailLinks.isEmpty()) {
            return null;
        }

        Id versionId = thumbnailLinks[0].ContentDocument.LatestPublishedVersionId;
        return URL.getOrgDomainUrl().toExternalForm()
            + '/sfc/servlet.shepherd/version/renditionDownload?rendition=' + THUMBNAIL_RENDITION
            + '&versionId=' + versionId;
    }
}
