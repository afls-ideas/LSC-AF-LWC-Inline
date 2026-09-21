import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

/**
 * Life Sciences example for the lightning__AgentforceOutput target: shows an
 * open support Case's status, priority, and SLA due date for the account the
 * rep is engaging with, so it can be glanced at mid-conversation.
 *
 * See CaseEscalationSummaryWrapper for the Apex-side field names. Follows
 * the same dual Web/Mobile data path as the sampleAgentforceOutputLWC
 * template: Web sets the @api `value` property directly; the AFLS mobile
 * app instead resolves data via lightning/navigation's PageReference state
 * params (c__<FieldName>), only accepting them once c__channel === 'Mobile'
 * marks the page-ref as the real mobile payload rather than an unrelated
 * re-fire.
 */
export default class CaseEscalationSummaryLWC extends LightningElement {
    _value = null;

    @api
    get value() {
        return this._value;
    }
    set value(val) {
        this._applyValue(val);
    }

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (this._value) return;

        const state = pageRef?.state;
        if (!state || state.c__channel !== 'Mobile') return;

        const caseId = this._parseStateParam(state.c__caseId);
        const caseNumber = this._parseStateParam(state.c__caseNumber);
        const subject = this._parseStateParam(state.c__subject);
        const status = this._parseStateParam(state.c__status);
        const priority = this._parseStateParam(state.c__priority);
        const accountName = this._parseStateParam(state.c__accountName);
        const slaDueDate = this._parseStateParam(state.c__slaDueDate);

        if (caseId == null && caseNumber == null && subject == null && status == null
            && priority == null && accountName == null && slaDueDate == null) {
            return;
        }

        this._applyValue({ caseId, caseNumber, subject, status, priority, accountName, slaDueDate });
    }

    _parseStateParam(raw) {
        if (raw === undefined || raw === null || raw === '') return null;
        if (typeof raw !== 'string') return raw;
        try {
            return JSON.parse(raw);
        } catch (e) {
            return raw;
        }
    }

    _applyValue(val) {
        this._value = val;
    }

    get _parsed() {
        if (!this._value) return null;
        if (typeof this._value === 'string') {
            try {
                return JSON.parse(this._value);
            } catch (e) {
                return null;
            }
        }
        return this._value;
    }

    get caseId() {
        return this._parsed?.caseId ?? '';
    }

    get hasCaseLink() {
        return !!this.caseId;
    }

    get caseUrl() {
        return this.caseId ? '/lightning/r/Case/' + this.caseId + '/view' : '';
    }

    get caseNumber() {
        return this._parsed?.caseNumber ?? '';
    }

    get subject() {
        return this._parsed?.subject ?? '';
    }

    get status() {
        return this._parsed?.status ?? '';
    }

    get priority() {
        return this._parsed?.priority ?? '';
    }

    get accountName() {
        return this._parsed?.accountName ?? '';
    }

    get slaDueDate() {
        return this._parsed?.slaDueDate ?? '';
    }

    get hasData() {
        return !!this._parsed;
    }

    get priorityClass() {
        const p = (this.priority || '').toLowerCase();
        if (p === 'high' || p === 'critical' || p === 'urgent') {
            return 'priority-badge priority-high';
        }
        if (p === 'medium') {
            return 'priority-badge priority-medium';
        }
        return 'priority-badge priority-low';
    }

    get statusClass() {
        const s = (this.status || '').toLowerCase();
        if (s.includes('closed') || s.includes('solved') || s.includes('resolved')) {
            return 'status-badge status-closed';
        }
        if (s.includes('escalat')) {
            return 'status-badge status-escalated';
        }
        if (s.includes('progress') || s.includes('working')) {
            return 'status-badge status-working';
        }
        return 'status-badge status-new';
    }
}
