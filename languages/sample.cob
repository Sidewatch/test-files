       IDENTIFICATION DIVISION.
       PROGRAM-ID. PAYROLL-SUMMARY.
      * Totals gross pay from the employee file and prints a summary.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT EMP-FILE ASSIGN TO "employees.dat"
               ORGANIZATION IS LINE SEQUENTIAL.
       DATA DIVISION.
       FILE SECTION.
       FD  EMP-FILE.
       01  EMP-RECORD.
           05  EMP-NAME      PIC X(30).
           05  EMP-HOURS     PIC 9(3)V9.
           05  EMP-RATE      PIC 9(3)V99.
       WORKING-STORAGE SECTION.
       01  WS-EOF            PIC X VALUE "N".
       01  WS-GROSS          PIC 9(7)V99 VALUE ZERO.
       01  WS-COUNT          PIC 9(5) VALUE ZERO.
       01  WS-DISPLAY        PIC Z(6)9.99.
       PROCEDURE DIVISION.
       MAIN-PARA.
           OPEN INPUT EMP-FILE
           PERFORM UNTIL WS-EOF = "Y"
               READ EMP-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END PERFORM ADD-PAY
               END-READ
           END-PERFORM
           CLOSE EMP-FILE
           MOVE WS-GROSS TO WS-DISPLAY
           DISPLAY "Employees: " WS-COUNT " Gross: " WS-DISPLAY
           STOP RUN.
       ADD-PAY.
           ADD 1 TO WS-COUNT
           COMPUTE WS-GROSS = WS-GROSS + EMP-HOURS * EMP-RATE.
