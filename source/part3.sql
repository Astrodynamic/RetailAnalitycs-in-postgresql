DROP OWNED BY Administrator;
DROP OWNED BY Visitor;

DROP ROLE IF EXISTS Visitor;
DROP ROLE IF EXISTS Administrator;

CREATE ROLE Administrator LOGIN PASSWORD 'admin';
GRANT ALL ON DATABASE tamara_store_db TO Administrator;
CREATE ROLE Visitor LOGIN PASSWORD 'visitor';

GRANT pg_read_all_data TO Visitor;

GRANT SELECT ON TABLE personal_data,
    cards,
    checks,
    group_sku,
    personal_data,
    segments,
    sku,
    stores,
    transactions TO Visitor;
GRANT postgres TO Administrator;

SELECT *
FROM pg_roles
where rolname = 'administrator'
   or rolname = 'visitor';