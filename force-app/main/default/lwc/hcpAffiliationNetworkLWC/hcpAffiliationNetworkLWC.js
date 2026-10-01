import { LightningElement, api, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';

const WIDTH = 600;
const HEIGHT = 380;
const ITERATIONS = 220;
const REPEL = 2600;
const SPRING_LENGTH = 95;
const SPRING_K = 0.02;
const CENTER_K = 0.012;
const DAMPING = 0.85;
const MARGIN = 34;

/**
 * Life Sciences example for the lightning__AgentforceOutput target: shows
 * an HCP's real affiliation network — the organizations they're
 * affiliated with and other providers who share those organizations — as
 * a force-directed graph. The layout (node x/y positions) is computed
 * client-side by a small spring/repulsion simulation (computeForceLayout
 * below); Apex only ever returns the raw graph (nodes + edges).
 *
 * Follows the same dual Web/Mobile data path as the other examples in this
 * library: Web sets the @api `value` property directly; the AFLS mobile
 * app instead resolves data via lightning/navigation's PageReference state
 * params (c__<FieldName>), only accepting them once c__channel === 'Mobile'
 * marks the page-ref as the real mobile payload rather than an unrelated
 * re-fire. `nodes` and `edges` are lists, so on mobile they each arrive as
 * one JSON-stringified array param rather than one param per field.
 */
export default class HcpAffiliationNetworkLWC extends LightningElement {
    _value = null;
    _layout = null;

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
        const nodes = this._parseStateParam(state.c__nodes);
        const edges = this._parseStateParam(state.c__edges);

        if (accountName == null && headline == null && nodes == null && edges == null) {
            return;
        }

        this._applyValue({ accountName, headline, nodes, edges });
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
        this._layout = null;
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

    get hasData() {
        return Array.isArray(this._parsed?.nodes) && this._parsed.nodes.length > 0;
    }

    get viewBox() {
        return `0 0 ${WIDTH} ${HEIGHT}`;
    }

    get graphNodes() {
        const positions = this._computedPositions;
        return (this._parsed?.nodes ?? [])
            .map((node) => {
                const pos = positions.get(node.id);
                if (!pos) return null;
                const isHcp = node.nodeType === 'HCP';
                return {
                    id: node.id,
                    x: pos.x,
                    y: pos.y,
                    labelY: pos.y + (node.isCenter ? 30 : 24),
                    radius: node.isCenter ? 20 : isHcp ? 11 : 14,
                    cssClass: 'node ' + (node.isCenter ? 'node-center' : isHcp ? 'node-hcp' : 'node-hco'),
                    label: node.label,
                    shortLabel: this._truncate(node.label)
                };
            })
            .filter((node) => node !== null);
    }

    get graphEdges() {
        const positions = this._computedPositions;
        return (this._parsed?.edges ?? [])
            .map((edge, index) => {
                const source = positions.get(edge.sourceId);
                const target = positions.get(edge.targetId);
                if (!source || !target) return null;
                const isHard = (edge.affiliationType ?? '').toLowerCase() === 'hard';
                const isStrong = !!edge.isPrimary || isHard;
                return {
                    key: index,
                    x1: source.x,
                    y1: source.y,
                    x2: target.x,
                    y2: target.y,
                    cssClass: 'edge ' + (isStrong ? 'edge-strong' : 'edge-soft'),
                    strokeDasharray: isStrong ? null : '4 3',
                    title: (edge.role ? edge.role + ' — ' : '') + (edge.affiliationType ?? 'Affiliation') + (edge.isPrimary ? ' (primary)' : '')
                };
            })
            .filter((edge) => edge !== null);
    }

    get _computedPositions() {
        if (this._layout) return this._layout;
        const nodes = Array.isArray(this._parsed?.nodes) ? this._parsed.nodes : [];
        const edges = Array.isArray(this._parsed?.edges) ? this._parsed.edges : [];
        this._layout = computeForceLayout(nodes, edges, WIDTH, HEIGHT);
        return this._layout;
    }

    _truncate(label) {
        if (!label) return '';
        return label.length > 22 ? label.slice(0, 21) + '…' : label;
    }
}

/**
 * Runs a small spring/repulsion force simulation (every node repels every
 * other node; edges act as springs pulling their endpoints toward
 * SPRING_LENGTH apart; a weak center-gravity term keeps the graph from
 * drifting off-canvas) and returns the settled x/y position for each node
 * id. Decaying `alpha` over ITERATIONS cools the simulation so positions
 * converge rather than oscillate — the same idea as d3-force's alpha
 * decay, hand-rolled here since the graph is small enough (well under 25
 * nodes in this library) for an O(n^2) repulsion pass per iteration to be
 * cheap.
 */
function computeForceLayout(nodes, edges, width, height) {
    const positions = new Map();
    const n = nodes.length;
    if (n === 0) return positions;

    const sim = nodes.map((node, i) => {
        const angle = (2 * Math.PI * i) / n;
        const radius = node.isCenter ? 0 : Math.min(width, height) / 3.2;
        return {
            id: node.id,
            x: width / 2 + Math.cos(angle) * radius,
            y: height / 2 + Math.sin(angle) * radius,
            vx: 0,
            vy: 0,
            weight: node.isCenter ? 2.4 : 1
        };
    });

    const indexById = new Map(sim.map((p, i) => [p.id, i]));
    const edgeList = edges
        .map((e) => ({ a: indexById.get(e.sourceId), b: indexById.get(e.targetId) }))
        .filter((e) => e.a !== undefined && e.b !== undefined);

    for (let iter = 0; iter < ITERATIONS; iter++) {
        const alpha = 1 - iter / ITERATIONS;

        for (let i = 0; i < n; i++) {
            for (let j = i + 1; j < n; j++) {
                const dx = sim[i].x - sim[j].x;
                const dy = sim[i].y - sim[j].y;
                const distSq = Math.max(dx * dx + dy * dy, 1);
                const dist = Math.sqrt(distSq);
                const force = (REPEL / distSq) * alpha;
                const fx = (dx / dist) * force;
                const fy = (dy / dist) * force;
                sim[i].vx += fx / sim[i].weight;
                sim[i].vy += fy / sim[i].weight;
                sim[j].vx -= fx / sim[j].weight;
                sim[j].vy -= fy / sim[j].weight;
            }
        }

        for (const e of edgeList) {
            const a = sim[e.a];
            const b = sim[e.b];
            const dx = b.x - a.x;
            const dy = b.y - a.y;
            const dist = Math.max(Math.sqrt(dx * dx + dy * dy), 1);
            const force = SPRING_K * (dist - SPRING_LENGTH) * alpha;
            const fx = (dx / dist) * force;
            const fy = (dy / dist) * force;
            a.vx += fx / a.weight;
            a.vy += fy / a.weight;
            b.vx -= fx / b.weight;
            b.vy -= fy / b.weight;
        }

        for (const p of sim) {
            p.vx += (width / 2 - p.x) * CENTER_K * alpha;
            p.vy += (height / 2 - p.y) * CENTER_K * alpha;
            p.x += p.vx;
            p.y += p.vy;
            p.vx *= DAMPING;
            p.vy *= DAMPING;
            p.x = Math.min(width - MARGIN, Math.max(MARGIN, p.x));
            p.y = Math.min(height - MARGIN, Math.max(MARGIN, p.y));
        }
    }

    for (const p of sim) {
        positions.set(p.id, { x: p.x, y: p.y });
    }
    return positions;
}
