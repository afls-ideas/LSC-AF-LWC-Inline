/**
 * GetSignatureCaptureAction — invocable action for the "LWC Example Library"
 * demo agent. Returns a REAL open Case plus the org's real active standard
 * Pricebook2/PricebookEntry/Product2 catalog, for display as a Custom
 * Lightning Type renderer (c/signatureCaptureLWC via signatureCaptureCLT).
 * No canned data — resolves the most recently opened non-Closed case,
 * optionally filtered by case number or subject.
 *
 * The card itself does the product search, quantity tally, and a
 * confirmation-signature gesture entirely client-side, then creates a real
 * Order/OrderItem draft directly via client-side write, not a second
 * Agentforce action — matching this project's write-action convention.
 *
 * Top-level `global` + `@JsonAccess`, matching the request/result/type
 * classes, is what lets the `@apexClassType` CLT binding resolve when the
 * type is declared via an Agent Script `complex_data_type_name` output.
 *
 * Created by Peter Yeung on 2026-09-20.
 * Copyright © 2026 Salesforce. All rights reserved.
 */
@JsonAccess(serializable='always' deserializable='always')
global class GetSignatureCaptureAction {

    @InvocableMethod(
        label='Get Signature Capture Context'
        description='Looks up a real open Case (optionally filtered by case number or subject) and the org\'s real active priced product catalog, so the rep can log what was used and generate a draft order with a confirmation signature.')
    global static List<GetSignatureCaptureResult> get(List<GetSignatureCaptureRequest> requests) {
        List<GetSignatureCaptureResult> responses = new List<GetSignatureCaptureResult>();

        Id standardPricebookId = null;
        for (Pricebook2 pb : [SELECT Id FROM Pricebook2 WHERE IsStandard = true AND IsActive = true LIMIT 1]) {
            standardPricebookId = pb.Id;
        }

        for (GetSignatureCaptureRequest req : requests) {
            responses.add(buildCapture(req.caseNumber, standardPricebookId));
        }
        return responses;
    }

    private static GetSignatureCaptureResult buildCapture(String caseNumber, Id standardPricebookId) {
        GetSignatureCaptureResult resp = new GetSignatureCaptureResult();
        Case matched = findCase(caseNumber);

        if (matched == null) {
            resp.capture = null;
            resp.summary = String.isNotBlank(caseNumber)
                ? 'No open case was found matching "' + caseNumber + '".'
                : 'No open case was found in the org.';
            return resp;
        }

        if (standardPricebookId == null) {
            resp.capture = null;
            resp.summary = 'No active standard price book is configured, so usage can\'t be priced.';
            return resp;
        }

        List<SignatureCaptureLineWrapper> products = new List<SignatureCaptureLineWrapper>();
        for (PricebookEntry entry : [
            SELECT Id, UnitPrice, Product2Id, Product2.Name, Product2.ProductCode
            FROM PricebookEntry
            WHERE Pricebook2Id = :standardPricebookId
            AND IsActive = true
            AND Product2.IsActive = true
            ORDER BY Product2.Name
            LIMIT 200
        ]) {
            SignatureCaptureLineWrapper line = new SignatureCaptureLineWrapper();
            line.productId = entry.Product2Id;
            line.pricebookEntryId = entry.Id;
            line.productName = entry.Product2.Name;
            line.productCode = entry.Product2.ProductCode;
            line.unitPrice = entry.UnitPrice;
            products.add(line);
        }

        SignatureCaptureWrapper capture = new SignatureCaptureWrapper();
        capture.caseId = matched.Id;
        capture.caseNumber = matched.CaseNumber;
        capture.caseSubject = matched.Subject;
        capture.accountId = matched.AccountId;
        capture.accountName = matched.Account != null ? matched.Account.Name : null;
        capture.pricebookId = standardPricebookId;
        capture.products = products;

        resp.capture = capture;
        resp.summary = 'Case ' + matched.CaseNumber + ' (' + matched.Subject + ') is ready to log usage against — '
            + products.size() + ' priced products available.';
        return resp;
    }

    /** Optionally filtered by case number/subject; else the most recently
     *  opened non-Closed case in the org — returns the first real match. */
    private static Case findCase(String caseNumber) {
        String likePattern = String.isNotBlank(caseNumber) ? '%' + caseNumber + '%' : null;

        List<Case> matches = likePattern == null
            ? [
                SELECT Id, CaseNumber, Subject, AccountId, Account.Name
                FROM Case
                WHERE Status != 'Closed'
                ORDER BY CreatedDate DESC
                LIMIT 1
            ]
            : [
                SELECT Id, CaseNumber, Subject, AccountId, Account.Name
                FROM Case
                WHERE Status != 'Closed'
                AND (CaseNumber LIKE :likePattern OR Subject LIKE :likePattern)
                ORDER BY CreatedDate DESC
                LIMIT 1
            ];
        return matches.isEmpty() ? null : matches[0];
    }
}
