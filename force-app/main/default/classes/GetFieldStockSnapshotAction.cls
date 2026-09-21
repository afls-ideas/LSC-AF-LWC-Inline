/**
 * GetFieldStockSnapshotAction — invocable action for the "LWC Example Library"
 * demo agent. Returns a REAL on-hand inventory snapshot for a product,
 * queried live from ProductBatchItem, for display as a Custom Lightning
 * Type renderer (c/fieldStockSnapshotLWC via fieldStockSnapshotCLT).
 * No canned data — the lowest-quantity, soonest-to-expire active lot is
 * returned, optionally filtered by product name.
 *
 * reorderThreshold is a fixed business-rule constant (not a stored field on
 * ProductBatchItem); lastCountDate is the lot's real LastModifiedDate, used
 * as the closest available real proxy for "last counted".
 *
 * Top-level `global` + `@JsonAccess`, matching the request/result/type
 * classes, is what lets the `@apexClassType` CLT binding resolve when the
 * type is declared via an Agent Script `complex_data_type_name` output.
 *
 * Created by Peter Yeung on 2026-09-20.
 * Copyright © 2026 Salesforce. All rights reserved.
 */
@JsonAccess(serializable='always' deserializable='always')
global class GetFieldStockSnapshotAction {

    private static final Integer REORDER_THRESHOLD = 10;

    @InvocableMethod(
        label='Get Field Stock Snapshot'
        description='Returns the rep\'s real on-hand sample/device inventory snapshot for a product, queried live from ProductBatchItem, to display as a visual card.')
    global static List<GetFieldStockSnapshotResult> get(List<GetFieldStockSnapshotRequest> requests) {
        List<GetFieldStockSnapshotResult> responses = new List<GetFieldStockSnapshotResult>();
        for (GetFieldStockSnapshotRequest req : requests) {
            responses.add(buildSnapshot(req.productName));
        }
        return responses;
    }

    private static GetFieldStockSnapshotResult buildSnapshot(String productName) {
        String likePattern = String.isNotBlank(productName) ? '%' + productName + '%' : null;

        List<ProductBatchItem> lots = likePattern == null
            ? [
                SELECT Id, Name, RemainingQuantity, ExpirationDate, LastModifiedDate, Product.Name
                FROM ProductBatchItem
                WHERE IsActive = true
                ORDER BY RemainingQuantity ASC, ExpirationDate ASC
                LIMIT 1
            ]
            : [
                SELECT Id, Name, RemainingQuantity, ExpirationDate, LastModifiedDate, Product.Name
                FROM ProductBatchItem
                WHERE IsActive = true
                AND Product.Name LIKE :likePattern
                ORDER BY RemainingQuantity ASC, ExpirationDate ASC
                LIMIT 1
            ];

        GetFieldStockSnapshotResult resp = new GetFieldStockSnapshotResult();

        if (lots.isEmpty()) {
            resp.snapshot = null;
            resp.summary = String.isNotBlank(productName)
                ? 'No active field stock lots were found for a product matching "' + productName + '".'
                : 'No active field stock lots were found in the org.';
            return resp;
        }

        ProductBatchItem lot = lots[0];
        Integer qty = lot.RemainingQuantity != null ? lot.RemainingQuantity.intValue() : 0;

        FieldStockSnapshotWrapper snapshot = new FieldStockSnapshotWrapper();
        snapshot.productName = lot.Product != null ? lot.Product.Name : lot.Name;
        snapshot.onHandQty = qty;
        snapshot.reorderThreshold = REORDER_THRESHOLD;
        snapshot.isLowStock = qty <= REORDER_THRESHOLD;
        snapshot.lastCountDate = lot.LastModifiedDate.date().format();

        resp.snapshot = snapshot;
        resp.summary = snapshot.productName + ': ' + snapshot.onHandQty + ' on hand (reorder at '
            + snapshot.reorderThreshold + ')' + (snapshot.isLowStock ? ' — LOW STOCK' : '');
        return resp;
    }
}
