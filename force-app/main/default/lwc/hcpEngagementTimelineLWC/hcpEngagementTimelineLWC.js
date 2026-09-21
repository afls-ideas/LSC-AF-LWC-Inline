import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

/**
 * Life Sciences example for the lightning__AgentforceOutput target: shows a
 * multi-track chronological engagement timeline (Visit / Medical Insight /
 * Inquiry / Event Participation) for an HCP account.
 *
 * See HcpEngagementTimelineWrapper/HcpEngagementEventWrapper for the
 * Apex-side field names. Follows the same dual Web/Mobile data path as the
 * other examples in this library: Web sets the @api `value` property
 * directly; the AFLS mobile app instead resolves data via
 * lightning/navigation's PageReference state params (c__<FieldName>), only
 * accepting them once c__channel === 'Mobile' marks the page-ref as the
 * real mobile payload rather than an unrelated re-fire. `events` is a list,
 * so on mobile it arrives as a single JSON-stringified array param rather
 * than one param per field.
 */
export default class HcpEngagementTimelineLWC extends LightningElement {
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

        const accountName = this._parseStateParam(state.c__accountName);
        const headline = this._parseStateParam(state.c__headline);
        const events = this._parseStateParam(state.c__events);

        if (accountName == null && headline == null && events == null) {
            return;
        }

        this._applyValue({ accountName, headline, events });
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

    get accountName() {
        return this._parsed?.accountName ?? '';
    }

    get headline() {
        return this._parsed?.headline ?? '';
    }

    get events() {
        const rawEvents = this._parsed?.events;
        if (!Array.isArray(rawEvents)) return [];
        return rawEvents.map((event, index) => ({
            ...event,
            key: index,
            trackClass: 'track-badge track-' + this._trackSlug(event.track),
            trackIcon: this._trackIcon(event.track),
            statusClass: event.status ? 'status-badge status-' + this._statusSlug(event.status) : null,
            hasRecordUrl: !!event.recordUrl
        }));
    }

    _trackSlug(track) {
        return (track ?? '').toLowerCase().replace(/[^a-z]/g, '-');
    }

    _trackIcon(track) {
        switch (this._trackSlug(track)) {
            case 'visit':
                return 'utility:event';
            case 'medical-insight':
                return 'utility:knowledge_base';
            case 'inquiry':
                return 'utility:comments';
            case 'event-participation':
                return 'utility:groups';
            default:
                return 'utility:record';
        }
    }

    _statusSlug(status) {
        const slug = (status ?? '').toLowerCase().replace(/[^a-z]/g, '-');
        if (slug.includes('complet')) return 'completed';
        if (slug.includes('progress')) return 'in-progress';
        if (slug.includes('cancel') || slug.includes('no-show') || slug.includes('missed')) return 'canceled';
        if (slug.includes('plan') || slug.includes('scheduled') || slug.includes('submitted')) return 'planned';
        return 'default';
    }

    get hasData() {
        return !!this._parsed;
    }
}
