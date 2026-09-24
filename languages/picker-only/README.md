# Picker-only samples

These four languages share an extension with another language, so a file cannot name them:

| File | Detects as | Intended language |
|---|---|---|
| `coq.v` | Verilog | Coq |
| `matlab.m` | Objective-C | MATLAB |
| `mysql.sql` | SQL | MySQL |
| `tsql.sql` | SQL | T-SQL |

Open one, then pick the intended language from the language picker (the status bar's language segment) to test that path. Everything else in `languages/` is detected from its name.
