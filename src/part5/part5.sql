CREATE OR REPLACE FUNCTION fnc_personal_offers_increasing_frequency_visits(
    IN f_date timestamp,
    IN l_date timestamp,
    IN n_transactions int,
    IN max_ci float,
    IN max_sdt float,
    IN allowable_ms float
)
    RETURNS TABLE
            (
                Customer_ID                 bigint,
                Start_Date                  timestamp,
                End_Date                    timestamp,
                Required_Transactions_Count int,
                Group_Name                  varchar,
                Offer_Discount_Depth        int
            )
AS
$fnc_personal_offers_increasing_frequency_visits$
BEGIN
    RETURN QUERY
        SELECT DISTINCT AD.Customer_ID                                                       AS Customer_ID,
                        f_date                                                               AS Start_Date,
                        l_date                                                               AS End_Date,
                        first_value(AD.Required_Transactions_Count)
                        OVER (PARTITION BY AD.Customer_ID ORDER BY AD.Customer_ID, GAI DESC) AS Required_Transactions_Count,
                        first_value(AD.Group_Name)
                        OVER (PARTITION BY AD.Customer_ID ORDER BY AD.Customer_ID, GAI DESC) AS Group_Name,
                        (first_value(AD.GMD::float)
                         OVER (PARTITION BY AD.Customer_ID ORDER BY AD.Customer_ID, GAI DESC) *
                         100)::int                                                           AS Offer_Discount_Depth
        FROM (SELECT DISTINCT VC."Customer_ID"                                                       AS Customer_ID,

                              (extract(epoch from l_date - f_date)::float / 86400.0 / "Customer_Frequency")::int +
                              n_transactions                                                         AS Required_Transactions_Count,

                              GS.group_name                                                          AS Group_Name,

                              allowable_ms / 100.0 * avg(group_margin)
                                                     OVER (PARTITION BY VG.customer_id, VG.group_id) AS MAD,

                              VG.group_affinity_index                                                AS GAI,

                              VG.group_minimum_discount * 1.05                                       AS GMD
              FROM v_customers AS VC
                       JOIN v_group AS VG ON VG.customer_id = VC."Customer_ID"
                       JOIN group_sku AS GS ON VG.group_id = GS.group_id
              WHERE VG.group_churn_rate <= max_ci
                AND VG.group_discount_share <= max_sdt
              ORDER BY VC."Customer_ID") AS AD
        WHERE GMD < MAD;
END;
$fnc_personal_offers_increasing_frequency_visits$
    LANGUAGE plpgsql;


SELECT *
FROM fnc_personal_offers_increasing_frequency_visits(
        '2018-08-18 21:17:43.000000'::timestamp,
        '2018-08-18 21:17:43.000000'::timestamp,
        1,
        4,
        0.6,
        35.0
    );
