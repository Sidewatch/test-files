*&---------------------------------------------------------------------*
*& Report Z_INVENTORY_REPORT — stock levels below the reorder point
*&---------------------------------------------------------------------*
REPORT z_inventory_report.

TYPES: BEGIN OF ty_stock,
         matnr TYPE matnr,
         werks TYPE werks_d,
         labst TYPE labst,
       END OF ty_stock.

DATA: lt_stock TYPE STANDARD TABLE OF ty_stock,
      lv_count TYPE i VALUE 0.

CONSTANTS gc_threshold TYPE labst VALUE '25.000'.

START-OF-SELECTION.
  SELECT matnr werks labst FROM mard INTO TABLE lt_stock
    WHERE labst < gc_threshold.

  LOOP AT lt_stock INTO DATA(ls_stock).
    lv_count = lv_count + 1.
    WRITE: / ls_stock-matnr, ls_stock-werks, ls_stock-labst.
  ENDLOOP.

  IF lv_count = 0.
    MESSAGE 'Nothing below the reorder point' TYPE 'S'.
  ELSE.
    MESSAGE |{ lv_count } materials need reordering| TYPE 'I'.
  ENDIF.
