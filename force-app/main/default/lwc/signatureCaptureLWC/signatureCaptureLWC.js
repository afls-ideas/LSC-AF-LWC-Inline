import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { createRecord } from 'lightning/uiRecordApi';

/**
 * Life Sciences example for the lightning__AgentforceOutput target: the
 * library's write-capable, interactive card. Data comes from a real
 * GetSignatureCaptureAction SOQL query (Case + active standard-pricebook
 * Product2/PricebookEntry) — no canned data. Product search, quantity
 * tally, and the confirmation-signature gesture all happen client-side
 * against that real catalog. Generate Draft Order performs a real
 * createRecord DML against Order and OrderItem — client-side write, not a
 * second Agentforce action, since inline output LWCs can't feed results
 * back into the agent's reasoning loop.
 *
 * The signature pad is a required confirmation gesture, not a stored
 * record or attachment — it gates the button but the drawn image itself
 * is never persisted.
 *
 * Same dual Web/Mobile data path as the rest of this library's examples:
 * Web sets the @api `value` property directly; mobile resolves data via
 * lightning/navigation's PageReference state params (c__<FieldName>), only
 * once c__channel === 'Mobile' marks the page-ref as the real payload.
 */
export default class SignatureCaptureLWC extends LightningElement {
    _value = null;

    searchTerm = '';
    usageLines = [];
    hasSignature = false;
    submitting = false;
    error;
    draftOrderId;

    _canvasBound = false;
    _drawing = false;

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
        const caseSubject = this._parseStateParam(state.c__caseSubject);
        const accountId = this._parseStateParam(state.c__accountId);
        const accountName = this._parseStateParam(state.c__accountName);
        const pricebookId = this._parseStateParam(state.c__pricebookId);
        const products = this._parseStateParam(state.c__products);

        if (
            caseId == null &&
            caseNumber == null &&
            accountName == null &&
            products == null
        ) {
            return;
        }

        this._applyValue({ caseId, caseNumber, caseSubject, accountId, accountName, pricebookId, products });
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

    get hasCapture() {
        return !!this._parsed;
    }

    get caseNumber() {
        return this._parsed?.caseNumber ?? '';
    }

    get caseSubject() {
        return this._parsed?.caseSubject ?? '';
    }

    get accountName() {
        return this._parsed?.accountName ?? '';
    }

    get products() {
        return this._parsed?.products ?? [];
    }

    get isReady() {
        return !this.draftOrderId;
    }

    get hasSearchTerm() {
        return this.searchTerm.trim().length > 0;
    }

    get searchResults() {
        const term = this.searchTerm.trim().toLowerCase();
        if (!term) return [];
        const addedIds = new Set(this.usageLines.map((l) => l.productId));
        return this.products
            .filter((p) => !addedIds.has(p.productId))
            .filter(
                (p) =>
                    (p.productName || '').toLowerCase().includes(term) ||
                    (p.productCode || '').toLowerCase().includes(term)
            )
            .slice(0, 8);
    }

    get hasSearchResults() {
        return this.searchResults.length > 0;
    }

    get usageRows() {
        return this.usageLines.map((line) => ({
            ...line,
            unitPriceFormatted: this._fmtCurrency(line.unitPrice),
            totalPriceFormatted: this._fmtCurrency(line.unitPrice * line.qty)
        }));
    }

    get usageCount() {
        return this.usageLines.length;
    }

    get canGenerate() {
        return (
            this.hasCapture &&
            this.usageLines.length > 0 &&
            this.hasSignature &&
            !this.submitting &&
            !this.draftOrderId
        );
    }

    get draftOrderUrl() {
        return this.draftOrderId ? `/lightning/r/Order/${this.draftOrderId}/view` : null;
    }

    renderedCallback() {
        if (this._canvasBound) return;
        const canvas = this.template.querySelector('canvas.signature-pad');
        if (!canvas) return;
        this._canvasBound = true;
        const ctx = canvas.getContext('2d');
        ctx.strokeStyle = '#181818';
        ctx.lineWidth = 2;
        ctx.lineCap = 'round';

        const pos = (evt) => {
            const rect = canvas.getBoundingClientRect();
            return { x: evt.clientX - rect.left, y: evt.clientY - rect.top };
        };
        canvas.addEventListener('pointerdown', (evt) => {
            this._drawing = true;
            const { x, y } = pos(evt);
            ctx.beginPath();
            ctx.moveTo(x, y);
        });
        canvas.addEventListener('pointermove', (evt) => {
            if (!this._drawing) return;
            const { x, y } = pos(evt);
            ctx.lineTo(x, y);
            ctx.stroke();
            if (!this.hasSignature) this.hasSignature = true;
        });
        ['pointerup', 'pointerleave'].forEach((evtName) => {
            canvas.addEventListener(evtName, () => {
                this._drawing = false;
            });
        });
    }

    handleSearchInput(event) {
        this.searchTerm = event.target.value;
    }

    handleAddProduct(event) {
        const id = event.currentTarget.dataset.id;
        const product = this.products.find((p) => p.productId === id);
        if (!product) return;
        this.usageLines = [
            ...this.usageLines,
            {
                productId: product.productId,
                pricebookEntryId: product.pricebookEntryId,
                name: product.productName,
                unitPrice: product.unitPrice,
                qty: 1
            }
        ];
        this.searchTerm = '';
    }

    handleQtyIncrement(event) {
        const id = event.currentTarget.dataset.id;
        this.usageLines = this.usageLines.map((l) =>
            l.productId === id ? { ...l, qty: l.qty + 1 } : l
        );
    }

    handleQtyDecrement(event) {
        const id = event.currentTarget.dataset.id;
        this.usageLines = this.usageLines
            .map((l) => (l.productId === id ? { ...l, qty: l.qty - 1 } : l))
            .filter((l) => l.qty > 0);
    }

    handleRemoveLine(event) {
        const id = event.currentTarget.dataset.id;
        this.usageLines = this.usageLines.filter((l) => l.productId !== id);
    }

    handleClearSignature() {
        const canvas = this.template.querySelector('canvas.signature-pad');
        if (canvas) {
            canvas.getContext('2d').clearRect(0, 0, canvas.width, canvas.height);
        }
        this.hasSignature = false;
    }

    handleGenerateDraftOrder() {
        if (!this.canGenerate) return;
        this.submitting = true;
        this.error = undefined;

        const capture = this._parsed;
        const today = new Date().toISOString().slice(0, 10);

        createRecord({
            apiName: 'Order',
            fields: {
                AccountId: capture.accountId,
                Status: 'Draft',
                EffectiveDate: today,
                Pricebook2Id: capture.pricebookId,
                Description: `Signature capture — Case ${capture.caseNumber}`
            }
        })
            .then((order) => {
                const lineCreates = this.usageLines.map((line) =>
                    createRecord({
                        apiName: 'OrderItem',
                        fields: {
                            OrderId: order.id,
                            Product2Id: line.productId,
                            PricebookEntryId: line.pricebookEntryId,
                            Quantity: line.qty,
                            UnitPrice: line.unitPrice
                        }
                    })
                );
                return Promise.all(lineCreates).then(() => order);
            })
            .then((order) => {
                this.draftOrderId = order.id;
                this.submitting = false;
            })
            .catch((e) => {
                this.error = this._fmtError(e);
                this.submitting = false;
            });
    }

    _fmtCurrency(amount) {
        if (amount === undefined || amount === null) return '—';
        return `$${Number(amount).toLocaleString(undefined, { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
    }

    _fmtError(e) {
        if (!e) return null;
        return e.body?.message || e.message || JSON.stringify(e);
    }
}
