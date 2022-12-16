CREATE OR REPLACE FUNCTION fnc_formation_personal_offers_cross_selling(
    IN cnt_group int,
    IN max_churn_rate numeric,
    IN max_stability_index numeric,
    IN max_sku_share numeric,
    IN max_margin_share numeric
)
    RETURNS TABLE
            (
                Customer_ID          bigint,
                SKU_Name             varchar,
                Offer_Discount_Depth int
            )
AS
$fnc_formation_personal_offers_cross_selling$
BEGIN
    RETURN QUERY SELECT DISTINCT MD."Customer_ID",
                        MD.SN,
                        CASE
                            WHEN (MD.group_minimum_discount * 1.05 * 100)::int = 0 THEN 5
                            ELSE (MD.group_minimum_discount * 1.05 * 100)::int
                            END
                 FROM (SELECT dense_rank() OVER (PARTITION BY VG.customer_id ORDER BY VG.group_id) AS DR,
                              first_value(sku.sku_name) OVER (
                                  PARTITION BY VG.customer_id, VG.group_id
                                  ORDER BY (VB.sku_retail_price - VB.sku_purchase_price) DESC)     AS SN,
                              VG.group_id                                                          AS GI,
                              *
                       FROM v_group AS VG
                                JOIN v_bigdata AS VB ON VB.customer_id = VG.Customer_ID AND VB.group_id = VG.group_id
                                JOIN v_customers AS VC ON VC."Customer_ID" = VG.customer_id
                                JOIN sku ON sku.group_id = VG.group_id AND sku.sku_id = VB.sku_id
                       WHERE VC.customer_primary_store = VB.transaction_store_id
                         AND VG.group_churn_rate <= max_churn_rate
                         AND VG.group_stability_index < max_stability_index) AS MD
                 WHERE DR <= cnt_group
                   AND (SELECT count(*) FILTER ( WHERE sku.sku_name = MD.SN)::numeric / count(*)
                        FROM v_bigdata AS VB
                                 JOIN sku ON sku.sku_id = VB.sku_id
                        WHERE VB.customer_id = MD."Customer_ID"
                          AND VB.group_id = MD.GI) < max_sku_share
                   AND (MD.sku_retail_price - MD.sku_purchase_price) * max_margin_share / 100.0 / MD.sku_retail_price >=
                       MD.group_minimum_discount * 1.05;
END ;
$fnc_formation_personal_offers_cross_selling$
    LANGUAGE plpgsql;

SELECT *
FROM fnc_formation_personal_offers_cross_selling(100, 100, 100, 2, 10)