import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

/**
 * Template inline component for the lightning__AgentforceOutput target.
 *
 * Web renders this component by setting the @api `value` property directly.
 * The AFLS mobile app instead resolves it via lightning/navigation's
 * PageReference, because the mobile Agentforce output surface passes data
 * as URL/page-state params rather than component properties. Each field of
 * the Apex wrapper class (see SampleAgentforceOutputWrapper) arrives as its
 * own JSON-stringified state param, namespaced "c__<FieldName>".
 *
 * Both paths are normalized into the same _value shape below, so the rest
 * of the component (getters, template) never needs to know which surface
 * supplied the data.
 *
 * To create a new library entry from this template:
 *   1. Duplicate this LWC bundle and the sibling lightningTypes bundle.
 *   2. Write an Apex wrapper class with the fields your action returns.
 *   3. Update schema.json's "lightning:type" to point at the new wrapper.
 *   4. Update the sourceType name in this bundle's js-meta.xml.
 *   5. Update the c__<FieldName> keys in wiredPageRef() below to match
 *      the wrapper's field names.
 */
export default class SampleAgentforceOutputLWC extends LightningElement {
    _value = null;

    @api
    get value() {
        return this._value;
    }
    set value(val) {
        // The @api path (Web) is always allowed to (re)set.
        this._applyValue(val);
    }

    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        // Guard: CurrentPageReference re-fires on any navigation or state
        // change, so only accept a page-ref value the first time it's usable
        // and never let a later re-fire clobber a value already applied.
        if (this._value) return;

        const state = pageRef?.state;
        if (!state) return;

        const title = this._parseStateParam(state.c__title);
        const message = this._parseStateParam(state.c__message);
        const items = this._parseStateParam(state.c__items);

        if (title == null && message == null && items == null) return;

        this._applyValue({ title, message, items });
    }

    // State params always arrive as strings; parse into their real shape.
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

    get title() {
        return this._parsed?.title ?? '';
    }

    get message() {
        return this._parsed?.message ?? '';
    }

    get items() {
        return this._parsed?.items ?? [];
    }

    get hasItems() {
        return this.items.length > 0;
    }

    get hasData() {
        return !!(this.title || this.message || this.hasItems);
    }
}
