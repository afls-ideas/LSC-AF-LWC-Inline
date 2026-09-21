/**
 * GetHcpEngagementTimelineAction — invocable action for the "LWC Example
 * Library" demo agent. Returns a REAL, multi-track chronological timeline
 * for an account, queried live across four real objects, for display as a
 * Custom Lightning Type renderer (c/hcpEngagementTimelineLWC via
 * hcpEngagementTimelineCLT). No canned data:
 *   - Visit             -> Visit (AccountId)
 *   - Medical Insight   -> MedicalInsightAccount join to MedicalInsight
 *   - Event Participation -> LSDO_Medical_Conference_Activity__c (Account__c)
 *   - Inquiry           -> Inquiry (Account__c)
 * Not every account has records on every track — a track simply doesn't
 * appear rather than being fabricated. If no account is named, the account
 * with the most real Visit records is used.
 *
 * Top-level `global` + `@JsonAccess`, matching the request/result/type
 * classes, is what lets the `@apexClassType` CLT binding resolve when the
 * type is declared via an Agent Script `complex_data_type_name` output.
 *
 * Created by Peter Yeung on 2026-09-20.
 * Copyright © 2026 Salesforce. All rights reserved.
 */
@JsonAccess(serializable='always' deserializable='always')
global class GetHcpEngagementTimelineAction {

    private static final Integer MAX_EVENTS = 6;

    @InvocableMethod(
        label='Get HCP Engagement Timeline'
        description='Returns a real, multi-track chronological engagement timeline (visits, medical insights, inquiries, event participation) for an account, queried live, to display as a visual card.')
    global static List<GetHcpEngagementTimelineResult> get(List<GetHcpEngagementTimelineRequest> requests) {
        List<GetHcpEngagementTimelineResult> responses = new List<GetHcpEngagementTimelineResult>();
        for (GetHcpEngagementTimelineRequest req : requests) {
            responses.add(buildTimeline(req.accountName));
        }
        return responses;
    }

    private static GetHcpEngagementTimelineResult buildTimeline(String accountName) {
        GetHcpEngagementTimelineResult resp = new GetHcpEngagementTimelineResult();

        Id accountId;
        String resolvedName;

        if (String.isNotBlank(accountName)) {
            List<Account> matches = [SELECT Id, Name FROM Account WHERE Name LIKE :('%' + accountName + '%') LIMIT 1];
            if (matches.isEmpty()) {
                resp.timeline = null;
                resp.summary = 'No account matching "' + accountName + '" was found.';
                return resp;
            }
            accountId = matches[0].Id;
            resolvedName = matches[0].Name;
        } else {
            List<AggregateResult> top = [
                SELECT AccountId topAccountId
                FROM Visit
                WHERE AccountId != null
                GROUP BY AccountId
                ORDER BY COUNT(Id) DESC
                LIMIT 1
            ];
            if (top.isEmpty()) {
                resp.timeline = null;
                resp.summary = 'No engagement history was found in the org.';
                return resp;
            }
            accountId = (Id) top[0].get('topAccountId');
            resolvedName = [SELECT Name FROM Account WHERE Id = :accountId LIMIT 1].Name;
        }

        List<SortableEvent> sortable = new List<SortableEvent>();

        for (Visit v : [
            SELECT ActualVisitStartTime, PlannedVisitStartTime, Status, StatusRemarks, InstructionDescription
            FROM Visit
            WHERE AccountId = :accountId
            ORDER BY ActualVisitStartTime DESC NULLS LAST, PlannedVisitStartTime DESC NULLS LAST
            LIMIT 5
        ]) {
            Datetime eventWhen = v.ActualVisitStartTime != null ? v.ActualVisitStartTime : v.PlannedVisitStartTime;
            String detail = String.isNotBlank(v.StatusRemarks) ? v.StatusRemarks
                : (String.isNotBlank(v.InstructionDescription) ? v.InstructionDescription : 'No additional notes recorded.');
            sortable.add(new SortableEvent(eventWhen,
                buildEvent(eventWhen, 'Visit', null, detail, v.Status, '/lightning/r/Visit/' + v.Id + '/view')));
        }

        for (MedicalInsightAccount mia : [
            SELECT MedicalInsight.CreatedDate, MedicalInsight.Content, MedicalInsight.SourceType
            FROM MedicalInsightAccount
            WHERE AccountId = :accountId
            ORDER BY MedicalInsight.CreatedDate DESC
            LIMIT 5
        ]) {
            Datetime eventWhen = mia.MedicalInsight.CreatedDate;
            String title = 'Medical insight logged'
                + (String.isNotBlank(mia.MedicalInsight.SourceType) ? ' (' + mia.MedicalInsight.SourceType + ')' : '');
            sortable.add(new SortableEvent(eventWhen, buildEvent(eventWhen, 'Medical Insight', title, mia.MedicalInsight.Content)));
        }

        for (LSDO_Medical_Conference_Activity__c ep : [
            SELECT Interaction_Date__c, Conference_Name__c, Discussion_Topic__c
            FROM LSDO_Medical_Conference_Activity__c
            WHERE Account__c = :accountId
            ORDER BY Interaction_Date__c DESC
            LIMIT 5
        ]) {
            Datetime eventWhen = ep.Interaction_Date__c != null
                ? Datetime.newInstance(ep.Interaction_Date__c, Time.newInstance(0, 0, 0, 0))
                : null;
            sortable.add(new SortableEvent(eventWhen,
                buildEvent(eventWhen, 'Event Participation', 'Attended ' + ep.Conference_Name__c, ep.Discussion_Topic__c)));
        }

        for (Inquiry inq : [
            SELECT SubmittedDateTime, Type, Comment
            FROM Inquiry
            WHERE Account__c = :accountId
            ORDER BY SubmittedDateTime DESC
            LIMIT 5
        ]) {
            String detail = String.isNotBlank(inq.Comment) ? inq.Comment : 'No additional detail recorded.';
            sortable.add(new SortableEvent(inq.SubmittedDateTime, buildEvent(inq.SubmittedDateTime, 'Inquiry', inq.Type, detail)));
        }

        if (sortable.isEmpty()) {
            resp.timeline = null;
            resp.summary = resolvedName + ' has no recorded engagement history.';
            return resp;
        }

        sortable.sort();

        List<HcpEngagementEventWrapper> events = new List<HcpEngagementEventWrapper>();
        for (Integer i = 0; i < Math.min(MAX_EVENTS, sortable.size()); i++) {
            events.add(sortable[i].event);
        }

        HcpEngagementTimelineWrapper timeline = new HcpEngagementTimelineWrapper();
        timeline.accountName = resolvedName;
        timeline.headline = resolvedName + ': ' + sortable.size() + ' engagement touchpoint'
            + (sortable.size() == 1 ? '' : 's') + ' found across visits, medical insights, event participation, and inquiries.';
        timeline.events = events;

        resp.timeline = timeline;
        resp.summary = timeline.headline;
        return resp;
    }

    private static HcpEngagementEventWrapper buildEvent(Datetime eventWhen, String track, String title, String detail) {
        return buildEvent(eventWhen, track, title, detail, null, null);
    }

    /** Overload for tracks that carry a real status (currently only Visit)
     *  and/or a real record to drill through to. Status is rendered as its
     *  own colored badge in the LWC rather than appended into the title. */
    private static HcpEngagementEventWrapper buildEvent(Datetime eventWhen, String track, String title, String detail, String status, String recordUrl) {
        HcpEngagementEventWrapper event = new HcpEngagementEventWrapper();
        event.eventDate = eventWhen != null ? eventWhen.date().format() : null;
        event.track = track;
        event.title = title;
        event.detail = detail;
        event.status = status;
        event.recordUrl = recordUrl;
        return event;
    }

    /** Sorts real events from every track into one chronological list (most
     *  recent first) without needing HcpEngagementEventWrapper itself to
     *  carry a sortable Datetime — it only exposes a display-formatted
     *  String, since that's all the CLT/LWC need. */
    private class SortableEvent implements Comparable {
        Datetime sortKey;
        HcpEngagementEventWrapper event;

        SortableEvent(Datetime sortKey, HcpEngagementEventWrapper event) {
            this.sortKey = sortKey;
            this.event = event;
        }

        public Integer compareTo(Object other) {
            SortableEvent that = (SortableEvent) other;
            if (this.sortKey == that.sortKey) return 0;
            if (this.sortKey == null) return 1;
            if (that.sortKey == null) return -1;
            return this.sortKey < that.sortKey ? 1 : -1;
        }
    }
}
