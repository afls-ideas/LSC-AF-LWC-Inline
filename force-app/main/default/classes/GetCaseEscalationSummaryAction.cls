/**
 * GetCaseEscalationSummaryAction — invocable action for the "LWC Example
 * Library" demo agent. Returns a REAL open case's status, priority, and SLA
 * due date for an account, queried live from Case (+ CaseMilestone), for
 * display as a Custom Lightning Type renderer (c/caseEscalationSummaryLWC
 * via caseEscalationSummaryCLT). No canned data — searches priority tiers
 * from Critical down to Low, preferring open cases, optionally filtered by
 * account name.
 *
 * SLA due date comes from the case's earliest incomplete CaseMilestone, a
 * real field — not every case has one, so slaDueDate can be null.
 *
 * Top-level `global` + `@JsonAccess`, matching the request/result/type
 * classes, is what lets the `@apexClassType` CLT binding resolve when the
 * type is declared via an Agent Script `complex_data_type_name` output.
 *
 * Created by Peter Yeung on 2026-09-20.
 * Copyright © 2026 Salesforce. All rights reserved.
 */
@JsonAccess(serializable='always' deserializable='always')
global class GetCaseEscalationSummaryAction {

    private static final List<String> PRIORITY_ORDER = new List<String>{ 'Critical', 'High', 'Medium', 'Low' };

    @InvocableMethod(
        label='Get Case Escalation Summary'
        description='Returns a real open case\'s status, priority, and SLA due date for an account, queried live from Case, to display as a visual card.')
    global static List<GetCaseEscalationSummaryResult> get(List<GetCaseEscalationSummaryRequest> requests) {
        List<GetCaseEscalationSummaryResult> responses = new List<GetCaseEscalationSummaryResult>();
        for (GetCaseEscalationSummaryRequest req : requests) {
            responses.add(buildSummary(req.accountName));
        }
        return responses;
    }

    private static GetCaseEscalationSummaryResult buildSummary(String accountName) {
        Case matched = findCase(accountName);

        GetCaseEscalationSummaryResult resp = new GetCaseEscalationSummaryResult();

        if (matched == null) {
            resp.summary = null;
            resp.output = String.isNotBlank(accountName)
                ? 'No cases were found for an account matching "' + accountName + '".'
                : 'No cases were found in the org.';
            return resp;
        }

        CaseEscalationSummaryWrapper summary = new CaseEscalationSummaryWrapper();
        summary.caseId = matched.Id;
        summary.caseNumber = matched.CaseNumber;
        summary.subject = matched.Subject;
        summary.status = matched.Status;
        summary.priority = matched.Priority;
        summary.accountName = matched.Account != null ? matched.Account.Name : accountName;
        summary.slaDueDate = (!matched.CaseMilestones.isEmpty() && matched.CaseMilestones[0].TargetDate != null)
            ? matched.CaseMilestones[0].TargetDate.date().format()
            : null;

        resp.summary = summary;
        resp.output = 'Case ' + summary.caseNumber + ' for ' + summary.accountName + ' is '
            + summary.status + ' (' + summary.priority + ' priority)'
            + (summary.slaDueDate != null ? ', SLA due ' + summary.slaDueDate + '.' : '.');
        return resp;
    }

    /** Tries each priority tier from Critical down to Low, open cases before
     *  closed, most recent first — returns the first real match. */
    private static Case findCase(String accountName) {
        String likePattern = String.isNotBlank(accountName) ? '%' + accountName + '%' : null;

        for (String priority : PRIORITY_ORDER) {
            List<Case> matches = likePattern == null
                ? [
                    SELECT CaseNumber, Subject, Status, Priority, Account.Name,
                           (SELECT TargetDate FROM CaseMilestones WHERE IsCompleted = false ORDER BY TargetDate ASC LIMIT 1)
                    FROM Case
                    WHERE Priority = :priority
                    ORDER BY IsClosed ASC, CreatedDate DESC
                    LIMIT 1
                ]
                : [
                    SELECT CaseNumber, Subject, Status, Priority, Account.Name,
                           (SELECT TargetDate FROM CaseMilestones WHERE IsCompleted = false ORDER BY TargetDate ASC LIMIT 1)
                    FROM Case
                    WHERE Priority = :priority
                    AND Account.Name LIKE :likePattern
                    ORDER BY IsClosed ASC, CreatedDate DESC
                    LIMIT 1
                ];
            if (!matches.isEmpty()) {
                return matches[0];
            }
        }
        return null;
    }
}
