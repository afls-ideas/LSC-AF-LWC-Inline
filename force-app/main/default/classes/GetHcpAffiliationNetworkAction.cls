/**
 * GetHcpAffiliationNetworkAction — invocable action for the "LWC Example
 * Library" demo agent. Returns a REAL affiliation network for an HCP,
 * queried live from ProviderAffiliation, for display as a Custom Lightning
 * Type renderer (c/hcpAffiliationNetworkLWC via hcpAffiliationNetworkCLT)
 * rendered as a force-directed graph:
 *   - Center node   -> the named HCP (Account)
 *   - Direct nodes   -> organizations the HCP is affiliated with (RelatedAccountId)
 *   - Colleague nodes -> other providers who share one of those organizations
 * No canned data. Not every HCP shares an organization with another
 * provider in the org — colleague nodes simply don't appear rather than
 * being fabricated. If no account is named, the HCP with the most real
 * ProviderAffiliation records is used.
 *
 * Top-level `global` + `@JsonAccess`, matching the request/result/type
 * classes, is what lets the `@apexClassType` CLT binding resolve when the
 * type is declared via an Agent Script `complex_data_type_name` output.
 *
 * Created by Peter Yeung on 2026-09-30.
 * Copyright © 2026 Salesforce. All rights reserved.
 */
@JsonAccess(serializable='always' deserializable='always')
global class GetHcpAffiliationNetworkAction {

    private static final Integer MAX_ORGANIZATIONS = 8;
    private static final Integer MAX_COLLEAGUES = 10;

    @InvocableMethod(
        label='Get HCP Affiliation Network'
        description='Returns a real affiliation network for an HCP — the organizations they are affiliated with and other providers who share those organizations — queried live from ProviderAffiliation, to display as a visual force-directed graph.')
    global static List<GetHcpAffiliationNetworkResult> get(List<GetHcpAffiliationNetworkRequest> requests) {
        List<GetHcpAffiliationNetworkResult> responses = new List<GetHcpAffiliationNetworkResult>();
        for (GetHcpAffiliationNetworkRequest req : requests) {
            responses.add(buildNetwork(req.accountName));
        }
        return responses;
    }

    private static GetHcpAffiliationNetworkResult buildNetwork(String accountName) {
        GetHcpAffiliationNetworkResult resp = new GetHcpAffiliationNetworkResult();

        Id centerId;
        String resolvedName;

        if (String.isNotBlank(accountName)) {
            List<Account> matches = [SELECT Id, Name FROM Account WHERE Name LIKE :('%' + accountName + '%') LIMIT 1];
            if (matches.isEmpty()) {
                resp.network = null;
                resp.summary = 'No account matching "' + accountName + '" was found.';
                return resp;
            }
            centerId = matches[0].Id;
            resolvedName = matches[0].Name;
        } else {
            List<AggregateResult> top = [
                SELECT AccountId topAccountId
                FROM ProviderAffiliation
                WHERE AccountId != null
                GROUP BY AccountId
                ORDER BY COUNT(Id) DESC
                LIMIT 1
            ];
            if (top.isEmpty()) {
                resp.network = null;
                resp.summary = 'No affiliation records were found in the org.';
                return resp;
            }
            centerId = (Id) top[0].get('topAccountId');
            resolvedName = [SELECT Name FROM Account WHERE Id = :centerId LIMIT 1].Name;
        }

        List<ProviderAffiliation> direct = [
            SELECT RelatedAccountId, AffiliationType, IsPrimary, Role
            FROM ProviderAffiliation
            WHERE AccountId = :centerId AND RelatedAccountId != null
            ORDER BY IsPrimary DESC, AffiliationType ASC
            LIMIT :MAX_ORGANIZATIONS
        ];

        if (direct.isEmpty()) {
            resp.network = null;
            resp.summary = resolvedName + ' has no recorded affiliations.';
            return resp;
        }

        Set<Id> orgIds = new Set<Id>();
        List<AffiliationEdgeWrapper> edges = new List<AffiliationEdgeWrapper>();
        for (ProviderAffiliation pa : direct) {
            orgIds.add(pa.RelatedAccountId);
            edges.add(buildEdge(centerId, pa.RelatedAccountId, pa.AffiliationType, pa.IsPrimary, pa.Role));
        }

        Set<Id> colleagueIds = new Set<Id>();
        for (ProviderAffiliation pa : [
            SELECT AccountId, RelatedAccountId, AffiliationType, IsPrimary, Role
            FROM ProviderAffiliation
            WHERE RelatedAccountId IN :orgIds AND AccountId != :centerId AND AccountId != null
            ORDER BY RelatedAccountId
            LIMIT 60
        ]) {
            if (colleagueIds.size() >= MAX_COLLEAGUES && !colleagueIds.contains(pa.AccountId)) continue;
            colleagueIds.add(pa.AccountId);
            edges.add(buildEdge(pa.AccountId, pa.RelatedAccountId, pa.AffiliationType, pa.IsPrimary, pa.Role));
        }

        Set<Id> allAccountIds = new Set<Id>{ centerId };
        allAccountIds.addAll(orgIds);
        allAccountIds.addAll(colleagueIds);

        List<AffiliationNodeWrapper> nodes = new List<AffiliationNodeWrapper>();
        for (Account acct : [SELECT Id, Name, RecordType.Name FROM Account WHERE Id IN :allAccountIds]) {
            AffiliationNodeWrapper node = new AffiliationNodeWrapper();
            node.id = acct.Id;
            node.label = acct.Name;
            node.nodeType = (acct.RecordType != null && acct.RecordType.Name == 'Healthcare Provider') ? 'HCP' : 'HCO';
            node.isCenter = (acct.Id == centerId);
            nodes.add(node);
        }

        HcpAffiliationNetworkWrapper network = new HcpAffiliationNetworkWrapper();
        network.accountName = resolvedName;
        network.headline = resolvedName + ' is affiliated with ' + orgIds.size()
            + ' organization' + (orgIds.size() == 1 ? '' : 's')
            + (colleagueIds.isEmpty() ? '.' : ', shared with ' + colleagueIds.size()
                + ' other provider' + (colleagueIds.size() == 1 ? '' : 's') + ' in this network.');
        network.nodes = nodes;
        network.edges = edges;

        resp.network = network;
        resp.summary = network.headline;
        return resp;
    }

    private static AffiliationEdgeWrapper buildEdge(Id sourceId, Id targetId, String affiliationType, Boolean isPrimary, String role) {
        AffiliationEdgeWrapper edge = new AffiliationEdgeWrapper();
        edge.sourceId = sourceId;
        edge.targetId = targetId;
        edge.affiliationType = affiliationType;
        edge.isPrimary = isPrimary;
        edge.role = role;
        return edge;
    }
}
