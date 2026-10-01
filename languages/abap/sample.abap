*&---------------------------------------------------------------------*
*& Report  Z_WAREHOUSE_STOCK
*&---------------------------------------------------------------------*
*& Lists warehouse stock below the reorder point and posts transfers.
*& TODO: split the transfer logic into its own global class.
*& FIXME: the unit conversion ignores batch-managed materials.
*&---------------------------------------------------------------------*
REPORT z_warehouse_stock LINE-SIZE 132 NO STANDARD PAGE HEADING MESSAGE-ID zwh.

" ── Comments ──────────────────────────────────────────────────────────
* A full-line comment starts with an asterisk in column one.
" A quote starts a comment anywhere else on the line.
DATA gv_comment TYPE string. " trailing comment after a statement

" ── Includes, tables, type pools ──────────────────────────────────────
INCLUDE zwh_constants.
TABLES: mara, mard.
TYPE-POOLS: abap, slis.

" ── Types ─────────────────────────────────────────────────────────────
TYPES: BEGIN OF ty_stock,
         matnr TYPE matnr,
         werks TYPE werks_d,
         lgort TYPE lgort_d,
         labst TYPE labst,
         meins TYPE meins,
       END OF ty_stock,
       tt_stock TYPE STANDARD TABLE OF ty_stock WITH DEFAULT KEY,
       ty_range TYPE RANGE OF matnr.

TYPES ty_amount TYPE p LENGTH 9 DECIMALS 2.

" ── Constants ─────────────────────────────────────────────────────────
CONSTANTS: gc_threshold TYPE labst VALUE '25.000',
           gc_plant     TYPE werks_d VALUE '1000',
           gc_true      TYPE abap_bool VALUE abap_true,
           gc_hex       TYPE x LENGTH 2 VALUE 'FF0A'.

" ── Data declarations ─────────────────────────────────────────────────
DATA: gt_stock TYPE tt_stock,
      gs_stock TYPE ty_stock,
      gv_count TYPE i VALUE 0,
      gv_total TYPE ty_amount,
      gv_ratio TYPE f VALUE '1.5E-3',
      gv_text  TYPE string,
      gv_date  TYPE d,
      gv_time  TYPE t,
      gv_flag  TYPE abap_bool.

FIELD-SYMBOLS: <ls_stock> TYPE ty_stock,
               <lv_any>   TYPE any.

DATA(go_ref) = NEW cl_abap_typedescr( ).
DATA(gv_inline) = 42.

" ── Selection screen ──────────────────────────────────────────────────
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_werks TYPE werks_d DEFAULT '1000' OBLIGATORY,
              p_test  AS CHECKBOX DEFAULT 'X'.
  SELECT-OPTIONS: s_matnr FOR mara-matnr.
SELECTION-SCREEN END OF BLOCK b1.

" ── Local class definition ────────────────────────────────────────────
INTERFACE lif_reorder.
  METHODS needs_reorder
    IMPORTING is_stock TYPE ty_stock
    RETURNING VALUE(rv_yes) TYPE abap_bool.
ENDINTERFACE.

CLASS lcx_stock_error DEFINITION INHERITING FROM cx_static_check.
  PUBLIC SECTION.
    DATA mv_matnr TYPE matnr READ-ONLY.
    METHODS constructor IMPORTING iv_matnr TYPE matnr OPTIONAL.
ENDCLASS.

CLASS lcl_warehouse DEFINITION FINAL.
  PUBLIC SECTION.
    INTERFACES lif_reorder.
    CLASS-DATA gv_instances TYPE i READ-ONLY.
    CLASS-METHODS class_constructor.
    METHODS constructor IMPORTING iv_plant TYPE werks_d DEFAULT '1000'.
    METHODS load
      IMPORTING it_range TYPE ty_range OPTIONAL
      EXPORTING et_stock TYPE tt_stock
      CHANGING  cv_count TYPE i
      RAISING   lcx_stock_error.
    METHODS post_transfer
      IMPORTING iv_matnr TYPE matnr
                iv_qty   TYPE labst
      RAISING   lcx_stock_error.
  PROTECTED SECTION.
    DATA mv_plant TYPE werks_d.
  PRIVATE SECTION.
    CONSTANTS mc_limit TYPE i VALUE 1000.
    METHODS convert_unit
      IMPORTING iv_qty TYPE labst
      RETURNING VALUE(rv_qty) TYPE labst.
ENDCLASS.

CLASS lcx_stock_error IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mv_matnr = iv_matnr.
  ENDMETHOD.
ENDCLASS.

CLASS lcl_warehouse IMPLEMENTATION.
  METHOD class_constructor.
    gv_instances = 0.
  ENDMETHOD.

  METHOD constructor.
    mv_plant = iv_plant.
    gv_instances = gv_instances + 1.
  ENDMETHOD.

  METHOD lif_reorder~needs_reorder.
    rv_yes = xsdbool( is_stock-labst < gc_threshold ).
  ENDMETHOD.

  METHOD load.
    SELECT matnr, werks, lgort, labst, meins
      FROM mard
      INTO CORRESPONDING FIELDS OF TABLE @et_stock
      WHERE werks = @mv_plant
        AND matnr IN @it_range
        AND labst <> 0
      ORDER BY matnr ASCENDING.
    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE lcx_stock_error EXPORTING iv_matnr = '000000'.
    ENDIF.
    cv_count = lines( et_stock ).
  ENDMETHOD.

  METHOD post_transfer.
    DATA(lv_qty) = convert_unit( iv_qty ).
    IF lv_qty > mc_limit OR lv_qty <= 0.
      RAISE EXCEPTION TYPE lcx_stock_error EXPORTING iv_matnr = iv_matnr.
    ENDIF.
    CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
      EXPORTING
        goodsmvt_code = '04'
      EXCEPTIONS
        OTHERS        = 1.
    IF sy-subrc = 0.
      COMMIT WORK AND WAIT.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ENDMETHOD.

  METHOD convert_unit.
    rv_qty = iv_qty * 12 / 4 + ( iv_qty MOD 3 ) - ( iv_qty DIV 5 ) ** 2.
  ENDMETHOD.
ENDCLASS.

" ── Events and main flow ──────────────────────────────────────────────
INITIALIZATION.
  gv_date = sy-datum.
  gv_time = sy-uzeit.

AT SELECTION-SCREEN.
  IF p_werks IS INITIAL.
    MESSAGE e001 WITH 'Plant is required'.
  ENDIF.

START-OF-SELECTION.
  DATA(lo_wh) = NEW lcl_warehouse( p_werks ).

  TRY.
      lo_wh->load( IMPORTING et_stock = gt_stock CHANGING cv_count = gv_count ).
    CATCH lcx_stock_error INTO DATA(lx_err).
      MESSAGE |No stock for { lx_err->mv_matnr ALPHA = OUT }| TYPE 'E'.
    CLEANUP.
      CLEAR gt_stock.
  ENDTRY.

" ── Strings and templates ─────────────────────────────────────────────
  gv_text = 'It''s a text field literal'.
  gv_text = `Backtick string keeps trailing blanks   `.
  gv_text = |Pipe template: { gv_count } items on { gv_date DATE = ISO }, \| escaped bar, line\nbreak|.
  gv_text = |{ gv_count WIDTH = 8 ALIGN = RIGHT PAD = '0' }|.
  gv_text = TEXT-002.

" ── Numbers and operators ─────────────────────────────────────────────
  gv_count = 0 + 1 - 2 * 3 / 4.
  gv_count = 17 MOD 5.
  gv_count = 17 DIV 5.
  gv_ratio = '3.14E+2'.
  gv_total = '1234567.89'.
  gv_count += 1.
  gv_count -= 1.
  gv_count *= 2.
  gv_count /= 2.
  gv_text &&= | more|.
  gv_flag = xsdbool( gv_count BETWEEN 1 AND 10 ).
  gv_flag = xsdbool( gv_text CS 'stock' AND gv_text NS 'zzz' ).
  gv_flag = xsdbool( gv_text CP 'Pipe*' OR gv_text NP '#*' ).
  gv_flag = xsdbool( NOT gv_flag IS INITIAL AND gv_count IS NOT INITIAL ).
  gv_flag = xsdbool( gv_count EQ 1 OR gv_count NE 2 OR gv_count GT 3 OR gv_count LT 4
                  OR gv_count GE 5 OR gv_count LE 6 ).
  gv_flag = xsdbool( gv_count >= 1 AND gv_count <= 9 AND gv_count <> 5 ).
  gv_flag = xsdbool( gv_text IS ASSIGNED OR go_ref IS BOUND ).

" ── Control flow ──────────────────────────────────────────────────────
  IF gv_count = 0.
    MESSAGE 'Nothing below the reorder point' TYPE 'S'.
  ELSEIF gv_count < 10.
    WRITE: / 'A few items'.
  ELSE.
    MESSAGE |{ gv_count } materials need reordering| TYPE 'I'.
  ENDIF.

  CASE sy-ucomm.
    WHEN 'BACK' OR 'EXIT'.
      LEAVE PROGRAM.
    WHEN 'REFR'.
      PERFORM refresh_data.
    WHEN OTHERS.
      CONTINUE.
  ENDCASE.

  DO 3 TIMES.
    gv_count = gv_count + sy-index.
    IF gv_count > 100. EXIT. ENDIF.
  ENDDO.

  WHILE gv_count > 0.
    gv_count = gv_count - 10.
  ENDWHILE.

  LOOP AT gt_stock ASSIGNING <ls_stock> WHERE labst < gc_threshold.
    AT FIRST.
      WRITE / 'Low stock:'.
    ENDAT.
    WRITE: / <ls_stock>-matnr, <ls_stock>-werks, <ls_stock>-labst UNIT <ls_stock>-meins.
    AT LAST.
      SKIP.
      ULINE.
    ENDAT.
  ENDLOOP.

  LOOP AT gt_stock INTO DATA(ls_row) FROM 1 TO 5.
    CHECK ls_row-labst > 0.
    IF lo_wh->lif_reorder~needs_reorder( ls_row ) = abap_true.
      WRITE: / ls_row-matnr COLOR COL_NEGATIVE.
    ENDIF.
  ENDLOOP.

" ── Table operations and constructor expressions ──────────────────────
  READ TABLE gt_stock INTO gs_stock WITH KEY matnr = 'M-100' BINARY SEARCH.
  APPEND gs_stock TO gt_stock.
  INSERT INITIAL LINE INTO gt_stock INDEX 1 ASSIGNING <ls_stock>.
  DELETE gt_stock WHERE labst = 0.
  SORT gt_stock BY werks ASCENDING labst DESCENDING.
  DELETE ADJACENT DUPLICATES FROM gt_stock COMPARING matnr.
  MODIFY gt_stock FROM gs_stock TRANSPORTING labst WHERE matnr = gs_stock-matnr.

  DATA(lt_names) = VALUE string_table( ( `alpha` ) ( `beta` ) ( `gamma` ) ).
  DATA(lt_copy)  = CORRESPONDING tt_stock( gt_stock MAPPING matnr = matnr ).
  DATA(lv_sum)   = REDUCE i( INIT s = 0 FOR wa IN gt_stock NEXT s = s + wa-labst ).
  DATA(lt_flt)   = FILTER #( gt_stock WHERE labst < gc_threshold ).
  DATA(lv_cond)  = COND string( WHEN gv_count > 5 THEN `many` WHEN gv_count > 0 THEN `some` ELSE `none` ).
  DATA(lv_sw)    = SWITCH string( sy-datum+4(2) WHEN '12' THEN `winter` ELSE `other` ).
  DATA(lv_conv)  = CONV string( gv_count ).
  DATA(lv_cast)  = CAST cl_abap_typedescr( go_ref ).
  DATA(lv_line)  = gt_stock[ matnr = 'M-100' ].
  DATA(lv_opt)   = VALUE #( gt_stock[ 1 ] OPTIONAL ).

" ── String functions ──────────────────────────────────────────────────
  gv_text = to_upper( condense( gv_text ) ).
  gv_text = replace( val = gv_text sub = 'A' with = 'B' occ = 0 ).
  FIND REGEX '[0-9]+' IN gv_text MATCH COUNT gv_count.
  REPLACE ALL OCCURRENCES OF 'x' IN gv_text WITH 'y'.
  SPLIT gv_text AT ',' INTO TABLE lt_names.
  CONCATENATE 'a' 'b' INTO gv_text SEPARATED BY space.
  TRANSLATE gv_text TO UPPER CASE.
  SHIFT gv_text LEFT DELETING LEADING space.
  WRITE gv_text+2(3) TO gv_text.

" ── Subroutines, messages, dynamic access ─────────────────────────────
      " ── Further declarations and statements ───────────────────────────────
  "! ABAP Doc comment for the next declaration
  DATA gv_pragma TYPE i ##NEEDED.
  DATA gv_deep TYPE string ##NO_TEXT.
  TYPES: BEGIN OF ENUM ty_color STRUCTURE color,
           red,
           green VALUE IS INITIAL,
           blue,
         END OF ENUM ty_color STRUCTURE color.
  CONSTANTS gc_mask TYPE c LENGTH 4 VALUE 'ABCD'.
  CONSTANTS: BEGIN OF gc_state,
               open   TYPE c LENGTH 1 VALUE 'O',
               closed TYPE c LENGTH 1 VALUE 'C',
             END OF gc_state.
  DATA gt_sorted TYPE SORTED TABLE OF ty_stock WITH UNIQUE KEY matnr werks.
  DATA gt_hashed TYPE HASHED TABLE OF ty_stock WITH UNIQUE KEY matnr.
  DATA gr_ref TYPE REF TO data.
  DATA gv_packed TYPE p LENGTH 8 DECIMALS 3 VALUE '-1234.567'.
  DATA gv_bin TYPE xstring VALUE '0A0B0C'.
  DATA: gv_a TYPE i, gv_b TYPE i, gv_c TYPE i.
  DATA gv_lines LIKE LINE OF gt_stock.
  DATA gt_range TYPE RANGE OF matnr.
  STATICS sv_calls TYPE i.
  CLASS-DATA cv_shared TYPE i.
  FIELD-GROUPS header.
  RANGES r_werks FOR mard-werks.
  CONTROLS tc_stock TYPE TABLEVIEW USING SCREEN 0100.
  NODES mara.
  INFOTYPES 0001.

  DEFINE mac_inc.
    &1 = &1 + &2.
  END-OF-DEFINITION.
  mac_inc gv_a 5.

  " Open SQL beyond the basics
  SELECT SINGLE matnr, maktx FROM makt INTO @DATA(ls_makt) WHERE spras = @sy-langu.
  SELECT DISTINCT werks FROM mard INTO TABLE @DATA(lt_werks).
  SELECT werks, SUM( labst ) AS total, COUNT(*) AS cnt, AVG( labst ) AS mean, MAX( labst ) AS mx, MIN( labst ) AS mn
    FROM mard GROUP BY werks HAVING SUM( labst ) > 100 INTO TABLE @DATA(lt_agg).
  SELECT a~matnr, b~maktx FROM mara AS a INNER JOIN makt AS b ON a~matnr = b~matnr
    LEFT OUTER JOIN mard AS c ON c~matnr = a~matnr
    WHERE a~matkl LIKE 'TOOL%' AND b~spras IN ( 'E', 'D' ) AND c~labst IS NOT NULL
    ORDER BY a~matnr DESCENDING UP TO 10 ROWS INTO TABLE @DATA(lt_join).
  WITH +totals AS ( SELECT werks, SUM( labst ) AS s FROM mard GROUP BY werks )
    SELECT werks, s FROM +totals WHERE s > 0 INTO TABLE @DATA(lt_cte).
  SELECT matnr FROM mara UNION SELECT matnr FROM mard INTO TABLE @DATA(lt_union).
  SELECT matnr, CASE WHEN labst > 0 THEN 'X' ELSE ' ' END AS flag, concat( matnr, werks ) AS key
    FROM mard INTO TABLE @DATA(lt_case).
  SELECT * FROM mard WHERE matnr BETWEEN 'A' AND 'M' AND lgort NOT IN ( '0001' ) INTO TABLE @DATA(lt_all) PACKAGE SIZE 1000.
  ENDSELECT.
  OPEN CURSOR @DATA(lv_cursor) FOR SELECT matnr FROM mara.
  FETCH NEXT CURSOR @lv_cursor INTO TABLE @DATA(lt_fetch) PACKAGE SIZE 100.
  CLOSE CURSOR @lv_cursor.
  INSERT mard FROM @gs_stock.
  UPDATE mard SET labst = labst + 1 WHERE matnr = 'M-100'.
  MODIFY mard FROM TABLE @gt_stock.
  DELETE FROM mard WHERE labst = 0.
  INSERT zwh_log FROM TABLE @( VALUE #( ( matnr = 'M-1' ) ) ) ACCEPTING DUPLICATE KEYS.

  " Dynamic, references and runtime
  CREATE OBJECT go_ref.
  CREATE DATA gr_ref TYPE i.
  ASSIGN gr_ref->* TO <lv_any>.
  GET REFERENCE OF gv_a INTO gr_ref.
  ASSIGN COMPONENT 'MATNR' OF STRUCTURE gs_stock TO <lv_any>.
  ASSIGN gt_stock[ 1 ] TO <ls_stock>.
  DESCRIBE TABLE gt_stock LINES gv_count.
  DESCRIBE FIELD gv_text TYPE DATA(lv_type) LENGTH DATA(lv_len) IN CHARACTER MODE.
  CALL METHOD go_ref->('GET_RELATIVE_NAME').
  CALL FUNCTION 'DYNAMIC_FM' DESTINATION 'NONE' STARTING NEW TASK 'T1' PERFORMING done ON END OF TASK.
  CALL TRANSACTION 'MM03' USING gt_stock MODE 'N' UPDATE 'S'.
  CALL SCREEN 0100 STARTING AT 10 10 ENDING AT 60 20.
  SUBMIT z_other_report WITH p_werks = gc_plant WITH s_matnr IN s_matnr AND RETURN.
  SET PARAMETER ID 'MAT' FIELD gv_text.
  GET PARAMETER ID 'MAT' FIELD gv_text.
  EXPORT gt_stock TO MEMORY ID 'ZWH'.
  IMPORT gt_stock FROM MEMORY ID 'ZWH'.
  FREE MEMORY ID 'ZWH'.
  AUTHORITY-CHECK OBJECT 'M_MATE_WRK' ID 'WERKS' FIELD p_werks ID 'ACTVT' FIELD '03'.
  ASSERT gv_a >= 0.
  BREAK-POINT.
  LOG-POINT ID zwh SUBKEY 'x' FIELDS gv_a.
  SET HANDLER lo_wh->on_event FOR ALL INSTANCES.
  RAISE EVENT lo_event EXPORTING iv_x = 1.
  CASE TYPE OF go_ref.
    WHEN TYPE cl_abap_typedescr INTO DATA(lo_t).
      WRITE / 'typed'.
    WHEN OTHERS.
  ENDCASE.
  TRY.
      DATA(lv_div) = 1 / gv_c.
    CATCH cx_sy_zerodivide cx_sy_arithmetic_overflow INTO DATA(lx_math).
      RETRY.
  ENDTRY.
  RAISE EXCEPTION NEW cx_sy_itab_line_not_found( ).
  THROW cx_sy_zerodivide( ).

  " Files and strings
  OPEN DATASET 'out.txt' FOR OUTPUT IN TEXT MODE ENCODING UTF-8.
  TRANSFER gv_text TO 'out.txt'.
  READ DATASET 'out.txt' INTO gv_text.
  CLOSE DATASET 'out.txt'.
  CONVERT DATE gv_date TIME gv_time INTO TIME STAMP gv_total TIME ZONE sy-zonlo.
  COLLECT gs_stock INTO gt_stock.
  FIND ALL OCCURRENCES OF SUBSTRING 'a' IN gv_text RESULTS DATA(lt_found).
  OVERLAY gv_text WITH 'xyz'.
  PACK gv_text TO gv_text.
  UNPACK gv_text TO gv_text.
  GET BIT 3 OF gv_bin INTO gv_a.
  SET BIT 3 OF gv_bin TO 1.
  gv_a = gv_b BIT-AND gv_c.
  gv_a = ( gv_b BIT-OR gv_c ) BIT-XOR BIT-NOT gv_a.
  gv_a = 3 + 4 * 5 ** 2.
  gv_a = ipow( base = 2 exp = 8 ) + abs( -3 ) + sign( -1 ) + ceil( '1.2' ) + floor( '1.8' ) + round( val = '1.5' dec = 0 ) + sqrt( 16 ).
  gv_text = |{ 'abc' CASE = UPPER }{ gv_a SIGN = LEFT ZERO = NO NUMBER = USER }{ gv_date DATE = USER TIME = ISO }|.
  gv_text = cl_abap_char_utilities=>cr_lf && `tail`.

  " Screens and lists
  AT LINE-SELECTION.
    WRITE / 'Detail'.
  AT USER-COMMAND.
  AT PF01.
  TOP-OF-PAGE.
    WRITE / 'Header'.
  END-OF-PAGE.
  LOAD-OF-PROGRAM.
  SET PF-STATUS 'MAIN'.
  SET TITLEBAR 'T01' WITH 'Stock'.
  SET CURSOR FIELD 'P_WERKS'.
  LOOP AT SCREEN.
    screen-input = 0.
    MODIFY SCREEN.
  ENDLOOP.
  MODULE status_0100 OUTPUT.
  ENDMODULE.
  MODULE user_command_0100 INPUT.
  ENDMODULE.
  WRITE: /5 'Col 5', 20(10) gv_text COLOR COL_TOTAL INTENSIFIED OFF INVERSE ON HOTSPOT ON.
  HIDE gs_stock-matnr.
  NEW-PAGE LINE-SIZE 120.
  WINDOW STARTING AT 5 5.
  SELECTION-SCREEN COMMENT /1(60) TEXT-003.
  SELECTION-SCREEN PUSHBUTTON 1(20) btn USER-COMMAND run.
  SELECTION-SCREEN SKIP 1.
  SELECTION-SCREEN ULINE.
  PARAMETERS p_radio1 RADIOBUTTON GROUP g1 DEFAULT 'X'.
  PARAMETERS p_radio2 RADIOBUTTON GROUP g1.
  SELECT-OPTIONS s_werks FOR mard-werks NO INTERVALS NO-EXTENSION.

  " Obsolete-but-valid forms
  MOVE gv_a TO gv_b.
  MOVE-CORRESPONDING gs_stock TO gs_stock.
  ADD 1 TO gv_a.
  SUBTRACT 1 FROM gv_a.
  MULTIPLY gv_a BY 2.
  DIVIDE gv_a BY 2.
  COMPUTE gv_a = gv_b + 1.
  CLEAR: gv_a, gv_b.
  REFRESH gt_stock.
  FREE gt_stock.
  CHECK gv_a IS NOT INITIAL.
  RETURN.

FORM refresh_data.
  DATA lv_name TYPE string VALUE 'GV_COUNT'.
  ASSIGN (lv_name) TO <lv_any>.
  IF sy-subrc = 0.
    CLEAR <lv_any>.
  ENDIF.
  CALL METHOD cl_abap_char_utilities=>newline.
  GET TIME STAMP FIELD DATA(lv_ts).
  UNASSIGN <lv_any>.
ENDFORM.

END-OF-SELECTION.
  FORMAT COLOR COL_HEADING.
  WRITE: / 'Done', sy-uname, sy-datum.
  NEW-LINE.
  FORMAT RESET.
