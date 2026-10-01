      *> ===============================================================
      *> Warehouse stock summary in free-reference-style fixed format.
      *> Column 7 holds the indicator: '*' comment, '-' continuation,
      *> '/' page eject, 'D' debugging line.
      *> TODO: replace the sequential file with an indexed one.
      *> ===============================================================
       IDENTIFICATION DIVISION.
       PROGRAM-ID. STOCK-SUMMARY.
       AUTHOR. ACME LOGISTICS.
       INSTALLATION. CENTRAL WAREHOUSE.
       DATE-WRITTEN. 2026-01-01.
       DATE-COMPILED.
       SECURITY. INTERNAL USE ONLY.
      * A classic comment line with an asterisk in column 7.
      / A page-eject comment line.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       SOURCE-COMPUTER. GENERIC-HOST WITH DEBUGGING MODE.
       OBJECT-COMPUTER. GENERIC-HOST.
       SPECIAL-NAMES.
           DECIMAL-POINT IS COMMA
           CURRENCY SIGN IS "$"
           CLASS HEX-DIGIT IS "0" THRU "9" "A" THRU "F"
           SYMBOLIC CHARACTERS TAB-CHAR IS 10
           ALPHABET LOCAL-SEQ IS NATIVE
           UPSI-0 IS DEBUG-SWITCH ON STATUS IS DEBUG-ON.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT STOCK-FILE ASSIGN TO "stock.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               ACCESS MODE IS SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.
           SELECT INDEXED-FILE ASSIGN TO "stock.idx"
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS IDX-SKU
               ALTERNATE RECORD KEY IS IDX-NAME WITH DUPLICATES
               FILE STATUS IS WS-FILE-STATUS.
           SELECT REPORT-FILE ASSIGN TO PRINTER.
           SELECT SORT-FILE ASSIGN TO "sort.tmp".
       I-O-CONTROL.
           SAME AREA FOR STOCK-FILE INDEXED-FILE.

       DATA DIVISION.
       FILE SECTION.
       FD  STOCK-FILE
           RECORD CONTAINS 64 CHARACTERS
           LABEL RECORDS ARE STANDARD
           DATA RECORD IS STOCK-RECORD.
       01  STOCK-RECORD.
           05  STK-SKU        PIC X(8).
           05  STK-NAME       PIC X(30).
           05  STK-QTY        PIC 9(5).
           05  STK-PRICE      PIC 9(5)V99.
           05  STK-CATEGORY   PIC X.
               88  IS-TOOLS      VALUE "T".
               88  IS-PARTS      VALUE "P".
               88  IS-FASTENERS  VALUE "F" "S".
           05  FILLER         PIC X(13).
       FD  INDEXED-FILE.
       01  INDEXED-RECORD.
           05  IDX-SKU        PIC X(8).
           05  IDX-NAME       PIC X(30).
       FD  REPORT-FILE
           LINAGE IS 60 LINES WITH FOOTING AT 55.
       01  REPORT-LINE        PIC X(80).
       SD  SORT-FILE.
       01  SORT-RECORD.
           05  SORT-KEY       PIC X(8).
           05  SORT-DATA      PIC X(56).

       WORKING-STORAGE SECTION.
       77  WS-EOF             PIC X VALUE "N".
           88  AT-EOF            VALUE "Y".
       77  WS-FILE-STATUS     PIC XX.
       77  WS-COUNT           PIC 9(5) COMP VALUE ZERO.
       77  WS-INDEX           PIC S9(4) COMP-5.
       77  WS-RATE            COMP-1.
       77  WS-BIG             COMP-2.
       77  WS-PACKED          PIC S9(7)V99 COMP-3 VALUE +0.
       77  WS-BINARY          PIC 9(9) BINARY.
       01  WS-TOTALS.
           05  WS-GROSS       PIC 9(7)V99 VALUE ZERO.
           05  WS-TAX         PIC 9(5)V99 VALUE ZEROS.
           05  WS-NET         PIC S9(7)V99 SIGN IS LEADING SEPARATE.
       01  WS-DISPLAY         PIC Z(6)9.99.
       01  WS-CURRENCY        PIC $$,$$9.99CR.
       01  WS-EDITED          PIC ***,**9.99-.
       01  WS-DATE-TIME.
           05  WS-YEAR        PIC 9(4).
           05  WS-MONTH       PIC 99.
           05  WS-DAY         PIC 99.
       01  WS-TABLE.
           05  WS-ENTRY       OCCURS 10 TIMES
                              ASCENDING KEY IS WS-ENTRY-SKU
                              INDEXED BY ENTRY-IX.
               10  WS-ENTRY-SKU   PIC X(8).
               10  WS-ENTRY-QTY   PIC 9(5).
       01  WS-VARIABLE-TABLE.
           05  WS-COUNT-VAR   PIC 99.
           05  WS-ROW         OCCURS 1 TO 20 TIMES DEPENDING ON WS-COUNT-VAR.
               10  WS-ROW-DATA    PIC X(10).
       01  WS-REDEFINED       REDEFINES WS-DATE-TIME PIC X(8).
       01  WS-LONG-LITERAL    PIC X(60) VALUE "A literal that is too long
      -    " to fit on one line continues here".
       01  WS-HEX             PIC X(4) VALUE X"DEADBEEF".
       01  WS-BIN-LIT         PIC X(2) VALUE B"1010101010101010".
       01  WS-NATIONAL        PIC N(4) VALUE N"ABCD".
       01  WS-QUOTES          PIC X(20) VALUE 'single ''quoted'' text'.
       01  WS-NUMS.
           05  WS-N1          PIC 9V9 VALUE 1.5.
           05  WS-N2          PIC S9(3) VALUE -42.
           05  WS-N3          PIC 9(3) VALUE 1E2.
           05  WS-N4          PIC X(5) VALUE SPACES.
           05  WS-N5          PIC X(5) VALUE LOW-VALUES.
           05  WS-N6          PIC X(5) VALUE HIGH-VALUES.
           05  WS-N7          PIC X(5) VALUE ALL "*".
           05  WS-N8          PIC X(5) VALUE QUOTES.

       LOCAL-STORAGE SECTION.
       01  LS-TEMP            PIC 9(4).

       LINKAGE SECTION.
       01  LK-PARAM           PIC X(10).

       REPORT SECTION.
       SCREEN SECTION.
       01  MAIN-SCREEN.
           05  BLANK SCREEN.
           05  LINE 1 COLUMN 10 VALUE "STOCK SUMMARY".
           05  LINE 3 COLUMN 10 PIC X(10) USING LK-PARAM.

       PROCEDURE DIVISION USING LK-PARAM.
       DECLARATIVES.
       FILE-ERROR SECTION.
           USE AFTER STANDARD ERROR PROCEDURE ON STOCK-FILE.
       FILE-ERROR-PARA.
           DISPLAY "File error: " WS-FILE-STATUS.
       END DECLARATIVES.

       MAIN-PARA.
           DISPLAY "Starting " FUNCTION CURRENT-DATE UPON CONSOLE
           ACCEPT WS-DATE-TIME FROM DATE YYYYMMDD
           ACCEPT WS-INDEX FROM ARGUMENT-NUMBER
           OPEN INPUT STOCK-FILE
                OUTPUT REPORT-FILE
           PERFORM UNTIL AT-EOF
               READ STOCK-FILE
                   AT END SET AT-EOF TO TRUE
                   NOT AT END PERFORM ADD-STOCK
               END-READ
           END-PERFORM
           CLOSE STOCK-FILE REPORT-FILE
           PERFORM REPORT-PARA THRU REPORT-EXIT
           MOVE WS-GROSS TO WS-DISPLAY
           DISPLAY "Items: " WS-COUNT " Gross: " WS-DISPLAY
           STOP RUN.

       ADD-STOCK.
           ADD 1 TO WS-COUNT
           COMPUTE WS-GROSS ROUNDED = WS-GROSS + STK-QTY * STK-PRICE
               ON SIZE ERROR DISPLAY "Overflow"
               NOT ON SIZE ERROR CONTINUE
           END-COMPUTE
           EVALUATE TRUE
               WHEN IS-TOOLS
                   MOVE "tools" TO WS-N4
               WHEN IS-PARTS OR IS-FASTENERS
                   MOVE "small" TO WS-N4
               WHEN OTHER
                   MOVE SPACES TO WS-N4
           END-EVALUATE
           EVALUATE STK-QTY ALSO STK-CATEGORY
               WHEN 0 THRU 24 ALSO "T"
                   DISPLAY "low tools"
               WHEN ANY ALSO ANY
                   CONTINUE
           END-EVALUATE.

       REPORT-PARA.
           IF WS-COUNT = 0
               DISPLAY "Empty"
           ELSE IF WS-COUNT NOT > 5 AND WS-COUNT NOT = 3
               DISPLAY "Few"
           ELSE
               DISPLAY "Many"
           END-IF
           END-IF
           IF WS-GROSS IS GREATER THAN 1000 OR WS-GROSS IS NOT LESS THAN 10
               DISPLAY "Large"
           END-IF
           IF STK-CATEGORY IS ALPHABETIC AND STK-QTY IS NUMERIC
               DISPLAY "Valid"
           END-IF
           IF NOT AT-EOF AND WS-FILE-STATUS = "00"
               CONTINUE
           END-IF.

       REPORT-EXIT.
           EXIT.

       STATEMENTS-DEMO.
           MOVE 1 TO WS-INDEX
           MOVE ZERO TO WS-COUNT WS-GROSS
           MOVE "A" TO WS-N4(1:1)
           MOVE CORRESPONDING WS-TOTALS TO WS-TOTALS
           ADD 1 2 TO WS-COUNT GIVING WS-INDEX
           SUBTRACT 1 FROM WS-COUNT
           MULTIPLY 2 BY WS-COUNT GIVING WS-INDEX
           DIVIDE 10 BY 3 GIVING WS-INDEX REMAINDER LS-TEMP
           COMPUTE WS-NET = (WS-GROSS - WS-TAX) ** 2 / 3 + FUNCTION SQRT(16)
           PERFORM 3 TIMES
               ADD 1 TO WS-COUNT
           END-PERFORM
           PERFORM VARYING WS-INDEX FROM 1 BY 1
                   UNTIL WS-INDEX > 10 OR AT-EOF
               DISPLAY WS-INDEX
           END-PERFORM
           PERFORM ADD-STOCK 2 TIMES
           SEARCH WS-ENTRY
               AT END DISPLAY "not found"
               WHEN WS-ENTRY-SKU (ENTRY-IX) = "A-100"
                   DISPLAY "found"
           END-SEARCH
           SEARCH ALL WS-ENTRY
               WHEN WS-ENTRY-SKU (ENTRY-IX) = "B-200"
                   CONTINUE
           END-SEARCH
           SET ENTRY-IX UP BY 1
           SET ENTRY-IX TO 1
           STRING "A-" DELIMITED BY SIZE
                  STK-SKU DELIMITED BY SPACE
                  INTO WS-N4 WITH POINTER WS-INDEX
                  ON OVERFLOW DISPLAY "truncated"
           END-STRING
           UNSTRING WS-N4 DELIMITED BY "," OR ALL SPACE
                    INTO WS-N5 WS-N6 TALLYING IN WS-COUNT
           END-UNSTRING
           INSPECT WS-N4 TALLYING WS-COUNT FOR ALL "A"
           INSPECT WS-N4 REPLACING FIRST "A" BY "B"
           INSPECT WS-N4 CONVERTING "abc" TO "ABC"
           INITIALIZE WS-TOTALS REPLACING NUMERIC DATA BY ZERO
           SORT SORT-FILE ON ASCENDING KEY SORT-KEY
                USING STOCK-FILE GIVING INDEXED-FILE
           MERGE SORT-FILE ON ASCENDING KEY SORT-KEY
                USING STOCK-FILE INDEXED-FILE GIVING REPORT-FILE
           WRITE REPORT-LINE FROM WS-DISPLAY
               AFTER ADVANCING 2 LINES
           WRITE STOCK-RECORD INVALID KEY DISPLAY "dup" END-WRITE
           REWRITE STOCK-RECORD
           DELETE INDEXED-FILE RECORD
           START INDEXED-FILE KEY IS NOT LESS THAN IDX-SKU
           CALL "SUBPROG" USING BY REFERENCE WS-COUNT
                                BY CONTENT WS-INDEX
                                BY VALUE 5
                          RETURNING WS-NET
               ON EXCEPTION DISPLAY "no such program"
           END-CALL
           CANCEL "SUBPROG"
           GO TO REPORT-EXIT
           GO TO ADD-STOCK REPORT-PARA DEPENDING ON WS-INDEX
           ALTER ADD-STOCK TO PROCEED TO REPORT-PARA
           DISPLAY "Line " WITH NO ADVANCING
           ACCEPT WS-N4 FROM CONSOLE
           DISPLAY MAIN-SCREEN
           CONTINUE
           EXIT PROGRAM
           EXIT PARAGRAPH
           GOBACK
           STOP RUN.

      D    DISPLAY "Debugging line (column 7 = D)".

       END PROGRAM STOCK-SUMMARY.

      *> ── Further constructs: a second, nested program ────────────────
       IDENTIFICATION DIVISION.
       PROGRAM-ID. HELPER-PROG IS INITIAL.
       OPTIONS.
           ARITHMETIC IS STANDARD.
       ENVIRONMENT DIVISION.
       CONFIGURATION SECTION.
       REPOSITORY.
           FUNCTION ALL INTRINSIC.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  HP-FLAGS.
           05  HP-ON          PIC 1 VALUE B"1".
           05  HP-SWITCH      PIC X VALUE "N".
               88  SWITCH-ON     VALUE "Y".
               88  SWITCH-OFF    VALUE "N".
       01  HP-POINTERS.
           05  HP-PTR         USAGE POINTER.
           05  HP-PROC-PTR    USAGE PROCEDURE-POINTER.
           05  HP-OBJ         USAGE OBJECT REFERENCE.
       01  HP-BIGNUM          PIC S9(18) USAGE COMP.
       01  HP-FLOAT-SHORT     USAGE FLOAT-SHORT.
       01  HP-FLOAT-LONG      USAGE FLOAT-LONG.
       01  HP-DEC             USAGE DECIMAL-128.
       01  HP-INDEX-ITEM      USAGE INDEX.
       01  HP-DISPLAY-1       PIC 9(3) USAGE DISPLAY.
       01  HP-NATIONAL        PIC N(10) USAGE NATIONAL.
       01  HP-JUSTIFIED       PIC X(10) JUSTIFIED RIGHT.
       01  HP-SYNC            PIC S9(4) COMP SYNCHRONIZED.
       01  HP-BLANK           PIC 9(4) BLANK WHEN ZERO.
       01  HP-EXTERNAL        PIC X(10) EXTERNAL.
       01  HP-GLOBAL          PIC X(10) GLOBAL.
       01  HP-CONSTANT        CONSTANT 42.
       01  HP-TYPEDEF         PIC 9(4) IS TYPEDEF.
       01  HP-TYPED           TYPE HP-TYPEDEF.
       78  HP-LEVEL-78        VALUE 100.
       66  HP-RENAMES         RENAMES HP-ON THRU HP-SWITCH.
       01  HP-ALPHA-CLASS     PIC X(8).
       01  HP-CHECK           PIC 9(5) VALUE ZEROES.
       01  HP-EDIT-1          PIC +ZZZ,ZZ9.99.
       01  HP-EDIT-2          PIC -(5)9.99.
       01  HP-EDIT-3          PIC 9(3)B9(3)/9(2)0.
       01  HP-EDIT-4          PIC $$$,$$9.99DB.
       01  HP-EDIT-5          PIC **,**9.
       LINKAGE SECTION.
       01  LK-IN              PIC X(20).
       01  LK-OUT             PIC X(20).
       PROCEDURE DIVISION USING BY REFERENCE LK-IN
                          RETURNING LK-OUT.
       HELPER-MAIN SECTION.
       HELPER-ENTRY.
           ENTRY "HELPER-ALT" USING LK-IN.
           MOVE FUNCTION UPPER-CASE(LK-IN) TO LK-OUT
           MOVE FUNCTION LENGTH(LK-IN) TO HP-BIGNUM
           MOVE FUNCTION TRIM(LK-IN LEADING) TO LK-OUT
           MOVE FUNCTION NUMVAL("12.5") TO HP-FLOAT-LONG
           MOVE FUNCTION CURRENT-DATE(1:8) TO HP-ALPHA-CLASS
           MOVE FUNCTION RANDOM(42) TO HP-FLOAT-SHORT
           COMPUTE HP-BIGNUM = FUNCTION MAX(1, 2, 3) + FUNCTION MOD(7, 3)
               + FUNCTION INTEGER-OF-DATE(20260101) + FUNCTION ABS(-5)
           SET ADDRESS OF LK-IN TO HP-PTR
           SET HP-PROC-PTR TO ENTRY "HELPER-ALT"
           SET SWITCH-ON TO TRUE
           SET HP-INDEX-ITEM TO 5
           IF LK-IN IS NOT ALPHABETIC-UPPER AND NOT SWITCH-OFF
               DISPLAY "mixed"
           END-IF
           IF HP-BIGNUM POSITIVE OR HP-BIGNUM NEGATIVE OR HP-BIGNUM ZERO
               CONTINUE
           END-IF
           IF HP-PTR = NULL OR HP-PTR NOT = NULLS
               CONTINUE
           END-IF
           EVALUATE FUNCTION MOD(HP-BIGNUM, 2) ALSO TRUE
               WHEN 0 ALSO SWITCH-ON
                   DISPLAY "even and on"
               WHEN OTHER
                   DISPLAY "other"
           END-EVALUATE
           PERFORM WITH TEST AFTER UNTIL HP-BIGNUM > 10
               ADD 1 TO HP-BIGNUM
           END-PERFORM
           PERFORM VARYING HP-BIGNUM FROM 1 BY 1 UNTIL HP-BIGNUM > 3
               AFTER HP-DISPLAY-1 FROM 1 BY 1 UNTIL HP-DISPLAY-1 > 2
               CONTINUE
           END-PERFORM
           ACCEPT HP-ALPHA-CLASS FROM TIME
           ACCEPT HP-ALPHA-CLASS FROM DAY-OF-WEEK
           ACCEPT HP-ALPHA-CLASS FROM ENVIRONMENT "HOME"
           DISPLAY "HOME" UPON ENVIRONMENT-NAME
           DISPLAY "x" UPON SYSERR
           INSPECT LK-IN REPLACING ALL "A" BY "B" AFTER INITIAL "C" BEFORE INITIAL "D"
           STRING LK-IN DELIMITED BY SIZE INTO LK-OUT
           ON OVERFLOW CONTINUE NOT ON OVERFLOW CONTINUE
           END-STRING
           JSON GENERATE LK-OUT FROM HP-FLAGS
           JSON PARSE LK-IN INTO HP-FLAGS
           XML GENERATE LK-OUT FROM HP-FLAGS
           ALLOCATE 100 CHARACTERS INITIALIZED RETURNING HP-PTR
           FREE HP-PTR
           INVOKE HP-OBJ "method" USING LK-IN RETURNING LK-OUT
           RAISE EXCEPTION EC-SIZE
           RESUME NEXT STATEMENT
           GENERATE REPORT-LINE
           INITIATE REPORT-FILE
           TERMINATE REPORT-FILE
           USE FOR DEBUGGING ON ALL PROCEDURES
           COMMIT
           ROLLBACK
           EXEC SQL
               SELECT COUNT(*) INTO :HP-BIGNUM FROM STOCK WHERE QTY < :HP-DISPLAY-1
           END-EXEC
           EXEC CICS RETURN END-EXEC
           COPY "helpers.cpy" REPLACING ==:TAG:== BY ==HP==.
           REPLACE ==OLD-TEXT== BY ==NEW-TEXT==.
           REPLACE OFF.
           >>SOURCE FORMAT IS FREE
           >>DEFINE DEBUG-MODE AS 1
           >>IF DEBUG-MODE DEFINED
               DISPLAY "debug"
           >>ELSE
               CONTINUE
           >>END-IF
           >>SOURCE FORMAT IS FIXED
           GOBACK.
       HELPER-EXIT.
           EXIT SECTION.
       END PROGRAM HELPER-PROG.
