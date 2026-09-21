import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

/**
 * Life Sciences example for the lightning__AgentforceOutput target: shows a
 * rep's on-hand sample/device inventory for a product and flags a low-stock
 * warning once onHandQty drops to or below reorderThreshold.
 *
 * See FieldStockSnapshotWrapper for the Apex-side field names. Follows the
 * same dual Web/Mobile data path as the sampleAgentforceOutputLWC template:
 * Web sets the @api `value` property directly; the AFLS mobile app instead
 * resolves data via lightning/navigation's PageReference state params
 * (c__<FieldName>), only accepting them once c__channel === 'Mobile' marks
 * the page-ref as the real mobile payload rather than an unrelated re-fire.
 */
export default class FieldStockSnapshotLWC extends LightningElement {
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

        const productName = this._parseStateParam(state.c__productName);
        const onHandQty = this._parseStateParam(state.c__onHandQty);
        const reorderThreshold = this._parseStateParam(state.c__reorderThreshold);
        const isLowStock = this._parseStateParam(state.c__isLowStock);
        const lastCountDate = this._parseStateParam(state.c__lastCountDate);

        if (productName == null && onHandQty == null && reorderThreshold == null
            && isLowStock == null && lastCountDate == null) {
            return;
        }

        this._applyValue({ productName, onHandQty, reorderThreshold, isLowStock, lastCountDate });
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

    get productName() {
        return this._parsed?.productName ?? '';
    }

    get onHandQty() {
        return this._parsed?.onHandQty ?? 0;
    }

    get reorderThreshold() {
        return this._parsed?.reorderThreshold ?? 0;
    }

    get isLowStock() {
        return !!this._parsed?.isLowStock;
    }

    get lastCountDate() {
        return this._parsed?.lastCountDate ?? '';
    }

    get hasData() {
        return !!this._parsed;
    }

    get statusLabel() {
        return this.isLowStock ? 'Low Stock' : 'In Stock';
    }

    get statusClass() {
        return this.isLowStock
            ? 'status-badge status-low'
            : 'status-badge status-ok';
    }
}
