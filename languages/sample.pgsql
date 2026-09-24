-- PL/pgSQL: a reorder function, a trigger and a DO block.
CREATE OR REPLACE FUNCTION reorder_needed(p_sku text, p_threshold integer DEFAULT 25)
RETURNS boolean
LANGUAGE plpgsql STABLE AS $$
DECLARE
    v_qty integer;
BEGIN
    SELECT qty INTO v_qty FROM stock WHERE sku = p_sku;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'unknown sku %', p_sku USING ERRCODE = 'no_data_found';
    END IF;
    RETURN v_qty <= p_threshold;
END;
$$;

CREATE OR REPLACE FUNCTION stock_audit() RETURNS trigger AS $$
BEGIN
    INSERT INTO stock_audit(sku, old_qty, new_qty, changed_at)
    VALUES (NEW.sku, OLD.qty, NEW.qty, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER stock_audit_trg AFTER UPDATE OF qty ON stock
    FOR EACH ROW WHEN (OLD.qty IS DISTINCT FROM NEW.qty) EXECUTE FUNCTION stock_audit();

DO $$
DECLARE r record;
BEGIN
    FOR r IN SELECT sku FROM stock WHERE reorder_needed(sku) LOOP
        RAISE NOTICE 'reorder %', r.sku;
    END LOOP;
END $$;
