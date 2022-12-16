-- 2.1
CREATE MATERIALIZED VIEW IF NOT EXISTS v_customers AS
WITH maininfo AS
         (SELECT PD.customer_id                      AS "CI",
                 TR.transaction_datetime             AS "TD",
                 TR.transaction_store_id             AS "TSI",
                 avg(TR.transaction_summ) OVER w_pci AS "ATS",
                 row_number() OVER w_pci_otd_d       AS rn,
                 count(*) OVER w_pcitsi              AS cnt

          FROM Personal_Data AS PD
                   JOIN Cards AS CR ON PD.customer_id = CR.customer_id
                   JOIN Transactions AS TR ON TR.customer_card_id = CR.customer_card_id
              WINDOW w_pci AS (PARTITION BY PD.customer_id),
                  w_pcitsi AS (PARTITION BY PD.customer_id, TR.transaction_store_id),
                  w_pci_otd_d AS (PARTITION BY PD.customer_id ORDER BY TR.transaction_datetime DESC)),
     cte2 AS (SELECT DISTINCT "CI",
                              first_value("TSI") OVER (PARTITION BY "CI" ORDER BY cnt DESC, "TD" DESC) AS preferred_shop,
                              first_value("TSI") OVER (PARTITION BY "CI" ORDER BY rn)                  AS last_shop
              FROM maininfo),
     cte3 AS (SELECT "CI",
                     count(DISTINCT "TSI") last_3_cnt
              FROM maininfo
              WHERE rn <= 3
              GROUP BY "CI")

SELECT "Customer_ID",
       "Customer_Average_Check",
       "Customer_Average_Check_Segment",
       "Customer_Frequency",
       "Customer_Frequency_Segment",
       "Customer_Inactive_Period",
       "Customer_Churn_Rate",
       "Customer_Churn_Segment",
       Segment AS "Segment",

       CASE
           WHEN last_3_cnt = 1 THEN last_shop
           ELSE preferred_shop
           END AS Customer_Primary_Store

FROM (SELECT "Customer_ID",
             "Customer_Average_Check",

             CASE
                 WHEN (percent_rank() OVER w_ocac_d < 0.1) THEN 'High'
                 WHEN (percent_rank() OVER w_ocac_d < 0.35) THEN 'Medium'
                 ELSE 'Low'
                 END                                           AS "Customer_Average_Check_Segment",

             "Customer_Frequency",

             CASE
                 WHEN (percent_rank() OVER w_ocf < 0.1) THEN 'Often'
                 WHEN (percent_rank() OVER w_ocf < 0.35) THEN 'Occasionally'
                 ELSE 'Rarely'
                 END                                           AS "Customer_Frequency_Segment",

             "Customer_Inactive_Period",

             "Customer_Inactive_Period" / "Customer_Frequency" AS "Customer_Churn_Rate",

             CASE
                 WHEN ("Customer_Inactive_Period" / "Customer_Frequency" < 2) THEN 'Low'
                 WHEN ("Customer_Inactive_Period" / "Customer_Frequency" < 5) THEN 'Medium'
                 ELSE 'High'
                 END                                           AS "Customer_Churn_Segment"

      FROM (SELECT "CI"                                    AS "Customer_ID",
                   "ATS"                                   AS "Customer_Average_Check",

                   extract(EPOCH from max("TD") - min("TD"))::float / 86400.0 /
                   count("CI")                             AS "Customer_Frequency",

                   extract(EPOCH from (SELECT Analysis_Date FROM Date_Of_Analysis_Formation) -
                                      max("TD")) / 86400.0 AS "Customer_Inactive_Period"
            FROM maininfo
            GROUP BY "CI", "ATS"
                WINDOW w_oats_d AS (ORDER BY sum("ATS") DESC)) AS avmain
      GROUP BY "Customer_ID",
               "Customer_Average_Check",
               "Customer_Frequency",
               "Customer_Inactive_Period"
          WINDOW w_ocac_d AS (ORDER BY sum("Customer_Average_Check") DESC),
              w_ocf AS (ORDER BY "Customer_Frequency")) AS biginfo
         JOIN Segments AS S ON (S.Average_Check = "Customer_Average_Check_Segment" AND
                                S.Purchase_Frequency = "Customer_Frequency_Segment" AND
                                S.Churn_Probability = "Customer_Churn_Segment")
         JOIN cte2 ON cte2."CI" = biginfo."Customer_ID"
         JOIN cte3 ON cte3."CI" = biginfo."Customer_ID";

CREATE MATERIALIZED VIEW IF NOT EXISTS v_bigdata AS
SELECT CR.customer_id,
       TR.transaction_id,
       TR.transaction_datetime,
       TR.transaction_store_id,
       SKU.group_id,
       CK.sku_amount,
       SR.sku_id,
       SR.sku_retail_price,
       SR.sku_purchase_price,
       CK.sku_summ_paid,
       CK.sku_summ,
       CK.sku_discount
FROM transactions AS TR
         JOIN cards AS CR ON CR.customer_card_id = TR.customer_card_id
         JOIN personal_data AS PD ON PD.customer_id = CR.customer_id
         JOIN checks AS CK ON TR.transaction_id = CK.transaction_id
         JOIN sku AS SKU ON SKU.sku_id = CK.sku_id
         JOIN stores AS SR ON SKU.sku_id = SR.sku_id AND
                              TR.transaction_store_id = SR.transaction_store_id;

-- 2.2
CREATE MATERIALIZED VIEW IF NOT EXISTS v_history AS
SELECT customer_id                          AS "Customer_ID",
       transaction_id                       AS "Transaction_ID",
       transaction_datetime                 AS "Transaction_DateTime",
       group_id                             AS "Group_ID",
       sum(sku_purchase_price * sku_amount) AS "Group_Cost",
       sum(sku_summ)                        AS "Group_Summ",
       sum(sku_summ_paid)                   AS "Group_Summ_Paid"
FROM v_bigdata
GROUP BY customer_id, transaction_id, transaction_datetime, group_id;

-- 2.3
CREATE MATERIALIZED VIEW IF NOT EXISTS v_periods AS
SELECT customer_id                          AS "Customer_ID",
       group_id                             AS "Group_ID",
       min(transaction_datetime)            AS "First_Group_Purchase_Date",
       max(transaction_datetime)            AS "Last_Group_Purchase_Date",
       count(DISTINCT transaction_id)       AS "Group_Purchase",
       (extract(EPOCH FROM max(transaction_datetime) - min(transaction_datetime))::float / 86400.0 + 1)
           / count(DISTINCT transaction_id) AS "Group_Frequency",
       min(sku_discount / sku_summ)         AS "Group_Min_Discount"
FROM v_bigdata
GROUP BY customer_id, group_id;

-- 2.4
CREATE MATERIALIZED VIEW IF NOT EXISTS v_more_info AS
SELECT VH."Customer_ID"               AS "Customer_ID",
       VH."Group_ID"                  AS "Group_ID",
       VH."Transaction_ID"            AS "Transaction_ID",
       VH."Transaction_DateTime"      AS "Transaction_DateTime",
       VH."Group_Cost"                AS "Group_Cost",
       VH."Group_Summ"                AS "Group_Summ",
       VH."Group_Summ_Paid"           AS "Group_Summ_Paid",
       VP."First_Group_Purchase_Date" AS "First_Group_Purchase_Date",
       VP."Last_Group_Purchase_Date"  AS "Last_Group_Purchase_Date",
       VP."Group_Purchase"            AS "Group_Purchase",
       VP."Group_Frequency"           AS "Group_Frequency",
       VP."Group_Min_Discount"        AS "Group_Min_Discount"
FROM v_periods AS VP
         JOIN v_history AS VH ON VH."Customer_ID" = VP."Customer_ID" AND
                                 VH."Group_ID" = VP."Group_ID";

CREATE OR REPLACE FUNCTION fnc_create_v_group(IN int default 1, IN interval default '5000 days'::interval,
                                              IN int default 100)
    RETURNS TABLE
            (
                Customer_ID            bigint,
                Group_ID               bigint,
                Group_Affinity_Index   float,
                Group_Churn_Rate       float,
                Group_Stability_Index  float,
                Group_Margin           float,
                Group_Discount_Share   float,
                Group_Minimum_Discount numeric,
                Group_Average_Discount numeric
            )
AS
$$
BEGIN
    RETURN QUERY
        SELECT "Customer_ID"                                      AS "Customer_ID",
               "Group_ID"                                         AS "Group_ID",
               "Group_Affinity_Index"                             AS "Group_Affinity_Index",
               "Group_Churn_Rate"                                 AS "Group_Churn_Rate",
               coalesce(avg("Group_Stability_Index"), 0)          AS "Group_Stability_Index",

               coalesce(CASE
                            WHEN ($1 = 1) THEN
                                        sum("Group_Margin"::float)
                                        FILTER (WHERE "Transaction_DateTime" BETWEEN (SELECT Analysis_Date FROM Date_Of_Analysis_Formation) - $2 AND
                                            (SELECT Analysis_Date FROM Date_Of_Analysis_Formation) )
                            WHEN ($1 = 2) THEN
                                (SELECT sum(GM)::float
                                 FROM (SELECT "Group_Summ_Paid" - "Group_Cost" as GM
                                       FROM v_more_info
                                       WHERE VMI."Customer_ID" = v_more_info."Customer_ID"
                                         AND VMI."Group_ID" = v_more_info."Group_ID"
                                       ORDER BY "Transaction_DateTime" DESC
                                       LIMIT $3) as SGM)
                            END, 0)                               AS "Group_Margin",

               "Group_Discount_Share",

               coalesce((SELECT min(sku_discount / sku_summ)
                         FROM v_bigdata AS VB
                         WHERE VB.customer_id = VMI."Customer_ID"
                           AND VB.group_id = VMI."Group_ID"
                           AND sku_discount / sku_summ > 0.0), 0) AS "Group_Minimum_Discount",

               avg(VMI."Group_Summ_Paid") / avg(VMI."Group_Summ") AS "Group_Average_Discount"


        from (SELECT "Customer_ID"                                          AS "Customer_ID",
                     "Group_ID"                                             AS "Group_ID",

                     "Group_Purchase"::float /
                     (SELECT count("Transaction_ID")
                      FROM v_more_info AS VMI
                      WHERE VMI."Customer_ID" = v_more_info."Customer_ID"
                        AND VMI."Transaction_DateTime"
                          BETWEEN v_more_info."First_Group_Purchase_Date"
                          AND v_more_info."Last_Group_Purchase_Date")       AS "Group_Affinity_Index",

                     extract(EPOCH from (SELECT Analysis_Date FROM Date_Of_Analysis_Formation) -
                                        max("Transaction_DateTime")
                                        OVER (PARTITION BY "Customer_ID", "Group_ID"))::float / 86400.0 /
                     "Group_Frequency"                                      AS "Group_Churn_Rate",

                     abs(extract(epoch from "Transaction_DateTime" - lag("Transaction_DateTime", 1)
                                                                     over (partition by "Customer_ID", "Group_ID"
                                                                         order by "Transaction_DateTime"))::float /
                         86400.0 - "Group_Frequency") / "Group_Frequency"   as "Group_Stability_Index",

                     "Group_Summ_Paid" - "Group_Cost"                       AS "Group_Margin",
                     "Transaction_DateTime",

                     (SELECT count(transaction_id)
                      FROM v_bigdata AS VB
                      WHERE v_more_info."Customer_ID" = VB.customer_id
                        AND v_more_info."Group_ID" = VB.group_id
                        AND VB.sku_discount != 0)::float / "Group_Purchase" AS "Group_Discount_Share",
                     "Group_Summ_Paid",
                     "Group_Summ"

              FROM v_more_info) as VMI
        GROUP BY "Customer_ID", "Group_ID", "Group_Affinity_Index", "Group_Churn_Rate", "Group_Discount_Share";
END ;
$$ LANGUAGE plpgsql;

CREATE MATERIALIZED VIEW v_group AS
select *
from fnc_create_v_group();