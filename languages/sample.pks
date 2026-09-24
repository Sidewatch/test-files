-- Oracle PL/SQL: a package spec and body for stock operations.
CREATE OR REPLACE PACKAGE stock_pkg AS
    c_reorder_point CONSTANT NUMBER := 25;
    TYPE sku_list IS TABLE OF VARCHAR2(20);

    FUNCTION low_stock RETURN sku_list PIPELINED;
    PROCEDURE adjust(p_sku IN VARCHAR2, p_delta IN NUMBER);
END stock_pkg;
/

CREATE OR REPLACE PACKAGE BODY stock_pkg AS
    FUNCTION low_stock RETURN sku_list PIPELINED IS
    BEGIN
        FOR r IN (SELECT sku FROM stock WHERE qty <= c_reorder_point ORDER BY price) LOOP
            PIPE ROW (r.sku);
        END LOOP;
        RETURN;
    END low_stock;

    PROCEDURE adjust(p_sku IN VARCHAR2, p_delta IN NUMBER) IS
        v_qty stock.qty%TYPE;
    BEGIN
        SELECT qty INTO v_qty FROM stock WHERE sku = p_sku FOR UPDATE;
        IF v_qty + p_delta < 0 THEN
            RAISE_APPLICATION_ERROR(-20001, 'stock cannot go negative for ' || p_sku);
        END IF;
        UPDATE stock SET qty = qty + p_delta WHERE sku = p_sku;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('unknown sku ' || p_sku);
    END adjust;
END stock_pkg;
/
