CREATE OR REPLACE FUNCTION fnc_get_first_date(num int, card_id bigint)
    RETURNS date AS
$$
DECLARE
    d date;
    n int;
BEGIN
    SELECT COUNT(transaction_id) INTO n FROM transactions WHERE customer_card_id = card_id;
    IF (n < num) THEN
        num = n;
    END IF;
    num = num - 1;
    SELECT transaction_datetime
    INTO d
    FROM transactions
    WHERE customer_card_id = card_id
    ORDER BY 1 DESC
    LIMIT 1 OFFSET num;

    RETURN d;
END ;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fnc_get_group_name(cus_id bigint, churn_ind numeric,
                                              max_share_of_transactions_w_discount numeric,
                                              allow_share_of_margin numeric) RETURNS varchar AS
$$
DECLARE
    name  varchar;
    name1 varchar;
    ofst  int DEFAULT 0; discount_depth numeric DEFAULT 0;
BEGIN
    WHILE (discount_depth = 0)
        LOOP
            SELECT group_name
            INTO name1
            FROM group_sku gs
                     JOIN v_group vg ON gs.group_id = vg.group_id
            WHERE cus_id = vg.customer_id
              AND group_churn_rate <= churn_ind
              AND group_discount_share < max_share_of_transactions_w_discount
            ORDER BY group_affinity_index DESC
            LIMIT 1 OFFSET ofst;
            EXIT WHEN (name1 IS NULL);
            discount_depth = fnc_get_offer_discount_depth(cus_id, name1, allow_share_of_margin);
            ofst = ofst + 1;
            name = name1;
        END LOOP;
    RETURN name;
END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fnc_get_offer_discount_depth(cus_id bigint, gr_name varchar, allow_share_of_margin numeric) RETURNS numeric AS
$$
DECLARE
    res          numeric DEFAULT 0;
    min_discount numeric ;
    gr_id        bigint DEFAULT 0;
BEGIN
    SELECT group_id INTO gr_id FROM group_sku WHERE group_name = gr_name LIMIT 1;
    SELECT AVG(group_margin) INTO res FROM v_group WHERE group_id = gr_id AND customer_id = cus_id LIMIT 1;
    SELECT group_minimum_discount INTO min_discount FROM v_group WHERE customer_id = cus_id AND group_id = gr_id;
--     res = ROUND((res * allow_share_of_margin + 2.9999999999999999) * 0.2) * 5;
    res = res * allow_share_of_margin;
    min_discount = ROUND((min_discount + 2.9999999999999999) * 0.2) * 5;
    IF (min_discount < res) THEN
        res = min_discount;
    ELSE
        res = 0;
    END IF;
    RETURN res;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fnc_growth_avg_check(method int, first_date date, last_date date, num_transactions int,
                                                avg_check_increase_coef numeric, max_churn_ind numeric,
                                                max_share_of_transactions_w_discount numeric,
                                                allow_share_of_margin numeric)
    RETURNS table
            (
                Customer_ID            bigint,
                Required_Check_Measure numeric,
                Group_Name             varchar,
                Offer_Discount_Depth   numeric
            )
AS
$$
BEGIN
    IF (method NOT IN (1, 2)) THEN
        RAISE EXCEPTION 'ERROR: wrong choice of method';
    END IF;
    IF (method = 1 AND first_date >= last_date) THEN
        RAISE EXCEPTION 'ERROR: first date should be early then last';
    ELSE
        SELECT MAX(transaction_datetime) INTO last_date FROM transactions LIMIT 1;
    END IF;
    RETURN QUERY
        SELECT DISTINCT pd.Customer_ID                                                                  AS Customer_ID,
                        (SELECT CASE
                                    WHEN method = 1 THEN (SELECT avg_check_increase_coef * AVG(sku_summ_paid)
                                                          FROM checks
                                                                   JOIN transactions t ON t.transaction_id = checks.transaction_id
                                                                   JOIN cards c ON c.customer_card_id = t.customer_card_id
                                                          WHERE pd.customer_id = c.customer_id
                                                            AND transaction_datetime BETWEEN first_date AND last_date
                                                          GROUP BY c.customer_id)
                                    WHEN method = 2 THEN (SELECT avg_check_increase_coef * AVG(sku_summ_paid)
                                                          FROM checks
                                                                   JOIN transactions t ON t.transaction_id = checks.transaction_id
                                                                   JOIN cards c ON c.customer_card_id = t.customer_card_id
                                                          WHERE pd.customer_id = c.customer_id
                                                            AND transaction_datetime BETWEEN fnc_get_first_date(num_transactions, t.customer_card_id) AND last_date
                                                          GROUP BY c.customer_id)
                                    END)                                                                AS Required_Check_Measure,
                        fnc_get_group_name(pd.customer_id, max_churn_ind,
                                           max_share_of_transactions_w_discount, allow_share_of_margin) AS Group_Name
                ,
                        GREATEST(fnc_get_offer_discount_depth(pd.customer_id,
                                                              fnc_get_group_name(pd.customer_id, max_churn_ind,
                                                                                 max_share_of_transactions_w_discount,
                                                                                 allow_share_of_margin),
                                                              allow_share_of_margin),
                                 5)                                                                     AS Offer_Discount_Depth
        FROM personal_data AS pd
        ORDER BY 2;

END;
$$ LANGUAGE plpgsql;


SELECT *
FROM fnc_growth_avg_check(2, '1.1.2018'::date, '2.12.2022'::date, 4, 1, 1.4, 4, 5)
WHERE Required_Check_Measure IS NOT NULL
  AND Group_Name IS NOT NULL;
