@echo off
:: Windows Batch (cmd.exe, Windows 11) — syntax showcase
:: Warehouse nightly build and stock export for Windows.
:: TODO: replace xcopy with robocopy.
REM Classic comment form, also valid.
rem Lowercase works too.
title Stock export
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul

:: ── Variables ───────────────────────────────────────────────────────
set CONFIG=Release
set "ROOT=%~dp0"
set "DROP=%USERPROFILE%\drops\%DATE:~-4%%DATE:~3,2%%DATE:~0,2%"
set /a built=0
set /a total=(3 + 4) * 2 %% 5
set /a bits="0xFF & 0x0F | 1 << 2"
set /a counter+=1
set /p reply=Continue (Y/N)? 
set EMPTY=
set PATH=%PATH%;C:\Tools\bin
set NAME=Widget
echo Value is %NAME% and substring %NAME:~0,3% and replaced %NAME:dget=XXX%

:: ── Built-in variables ──────────────────────────────────────────────
echo Script: %0 Dir: %~dp0 Name: %~n0 Ext: %~x0 Args: %* First: %1 Second: %~2
echo Time: %TIME% Date: %DATE% Random: %RANDOM% CD: %CD% Err: %ERRORLEVEL%
echo !built! !total! !NAME!

:: ── Conditionals ────────────────────────────────────────────────────
if not exist "%DROP%" mkdir "%DROP%"
if exist "%ROOT%config.ini" (
    echo Found config
) else (
    echo No config
)
if "%CONFIG%"=="Release" (echo release build) else (echo other build)
if /i "%CONFIG%"=="release" echo case-insensitive
if defined NAME echo NAME is defined
if not defined EMPTY echo EMPTY is not defined
if %built% EQU 0 echo none built
if %built% NEQ 0 echo some built
if %built% LSS 5 echo fewer than five
if %built% LEQ 5 echo at most five
if %built% GTR 5 echo more than five
if %built% GEQ 5 echo five or more
if errorlevel 1 echo non-zero exit code
if exist C:\Windows\System32\cmd.exe (echo cmd found)

:: ── Loops ───────────────────────────────────────────────────────────
for %%F in (*.csproj) do (
    echo Building %%~nF in %CONFIG% ...
    dotnet build "%%F" -c %CONFIG% || goto :fail
    set /a built+=1
)

for /L %%i in (1,1,5) do echo Step %%i
for /D %%d in (C:\Windows\*) do echo Dir %%d
for /R "%ROOT%" %%f in (*.log) do del "%%f"
for /F "tokens=1,2 delims=," %%a in (stock.csv) do echo SKU=%%a QTY=%%b
for /F "usebackq skip=1 tokens=*" %%l in (`type stock.csv`) do echo %%l
for /F %%v in ('ver') do echo %%v

:: ── Calls, labels and jumps ─────────────────────────────────────────
call :report "Nightly" 42
call "%ROOT%helper.bat" arg1 arg2
call set RESULT=%%NAME%%
goto :after_report

:report
setlocal
echo Report: %~1 with value %~2
endlocal & set LAST_REPORT=%~1
exit /b 0

:after_report
start "" /wait notepad.exe "%ROOT%notes.txt"
start /min cmd /c echo background

:: ── Redirection and pipes ───────────────────────────────────────────
dir /b *.csv > files.txt
dir /b *.log >> files.txt
type files.txt | find /c /v ""
sort < files.txt > sorted.txt
findstr /r /i "^A-[0-9]*" stock.csv 2>nul
echo ping & echo pong
copy nul empty.txt >nul 2>&1
ver | findstr /i "windows" >nul && echo windows || echo other
echo Escaped ^& ampersand, ^| pipe, ^> redirect, ^^ caret, %%percent
echo Unicode: é ü 世界

:: ── Common commands ─────────────────────────────────────────────────
xcopy /y /s /e /i bin\%CONFIG%\*.dll "%DROP%\" >nul
robocopy "%ROOT%src" "%DROP%\src" /MIR /NFL /NDL
copy /y "%ROOT%a.txt" "%DROP%\"
move "%ROOT%old.log" "%DROP%\"
ren "%DROP%\a.txt" b.txt
del /q /f "%TEMP%\*.tmp"
rd /s /q "%TEMP%\stock"
md "%TEMP%\stock"
attrib +r "%DROP%\b.txt"
tasklist /fi "imagename eq notepad.exe"
taskkill /im notepad.exe /f >nul 2>&1
timeout /t 2 /nobreak >nul
choice /c YN /m "Proceed"
cls
pause
shift
pushd "%ROOT%"
popd
mode con cols=100 lines=40
color 0A
prompt $P$G
assoc .txt
ftype txtfile
netstat -an | find "LISTEN"
reg query HKCU\Software\Acme /v Setting
schtasks /query /tn "Nightly"
wmic os get caption
:: wmic is deprecated (removed from current Windows 11); kept for highlighting. Prefer: powershell -Command "(Get-CimInstance Win32_OperatingSystem).Caption"
powershell -NoProfile -Command "Get-Date -Format s"

:: ── Success and failure exits ───────────────────────────────────────
echo Built !built! project(s)
endlocal
goto :eof

:fail
echo Build failed with error %ERRORLEVEL% 1>&2
exit /b 1

:: ── Further constructs ─────────────────────────────────────────────
@rem Another comment form with a leading at sign
@set "QUIET=1"
%COMSPEC% /c echo run through COMSPEC
::: Triple-colon comment
:: Labels and comment-labels
:main_entry
:Label_With_Underscores
:eof_label
:: Variable expansion forms
echo %~f0 %~d0 %~p0 %~n0 %~x0 %~s0 %~a0 %~t0 %~z0 %~$PATH:0
echo %~dp1 %~nx1 %~f2 %~1 %~2 %9 %*
echo !NAME:~1,2! !NAME:Wi=Wo! !NAME:~-3! !NAME:*d=!
echo %CD:~0,2% %TIME: =0% %DATE:/=-% %USERNAME% %COMPUTERNAME% %OS% %PROCESSOR_ARCHITECTURE%
echo %ProgramFiles(x86)% %SystemRoot% %APPDATA% %LOCALAPPDATA% %TEMP% %HOMEDRIVE%%HOMEPATH%
echo %CMDEXTVERSION% %CMDCMDLINE% %HIGHESTNUMANODENUMBER%
echo %%~dpnxF %%A %%b
:: Nested expansion and delayed expansion
set "list=a b c"
for %%i in (%list%) do (
    set "item=%%i"
    echo !item! !item:a=A!
    for /f "tokens=1-3 delims= " %%x in ("%list%") do echo %%x-%%y-%%z
)
set /a "n=5, m=n*2, n+=1, m<<=1, m>>=1, x=n&m, y=n|m, z=n^m, w=~n, v=!n, u=-n, t=n%%3, s=(n>3)?1:0"
set /a "hex=0x1F, oct=017, dec=31"
set /a "mixed = (3 + 4) * 2 / 7 - 1"
set /p "answer=Enter value: " 
set "multi=line1^
line2"
set var=with spaces
set "var=with trailing spaces   "
set var=
set v
set /?
:: Control characters and escapes
echo ^<tag^> ^& ^| ^^ ^! ^% ^"
echo "quoted & | < > ^ stays literal"
echo %%
echo.
echo(
echo.Line after dot
echo:Colon form
echo/Slash form
echo ON
echo OFF
@echo on
@echo off
echo Tab:	Tab
:: Conditionals, compound
if /i not "%1"=="" if exist "%1" echo arg is a file
if 1==1 (echo yes) else if 2==2 (echo two) else (echo no)
if "%ERRORLEVEL%" neq "0" (exit /b %ERRORLEVEL%)
if errorlevel 2 goto :two
if not errorlevel 1 echo success
if cmdextversion 2 echo extensions on
if /i "%~1"=="/help" goto :usage
if exist "%~dp0sub\" echo directory
if exist nul echo nul exists
if defined PATH echo has path
cmd /v:on /c "set X=1 & echo !X!"
cmd /e:on /f:on /k
:: Loops of every form
for %%a in (1 2 3) do @echo %%a
for %%a in ("a b" "c d") do @echo %%~a
for %%a in (*.txt *.log) do @echo %%~fa %%~za %%~ta
for /l %%n in (10,-2,0) do @echo %%n
for /d %%d in (*) do @echo dir %%d
for /r C:\ %%f in (*.sys) do @echo %%f
for /f "delims=" %%l in (file.txt) do @echo %%l
for /f "eol=# tokens=2* delims=, skip=2" %%a in (data.csv) do @echo %%a %%b
for /f "usebackq tokens=*" %%a in ("file with spaces.txt") do @echo %%a
for /f "tokens=1,2,3" %%a in ('wmic os get caption^,version') do @echo %%a %%b %%c
for /f %%a in ('dir /b ^| find /c /v ""') do set count=%%a
for /f %%a in ("literal string") do @echo %%a
for %%i in (a b c) do for %%j in (1 2) do echo %%i%%j
:: Subroutines, exit codes, arguments
call :sub arg1 "arg 2" %*
call :sub_return result
echo Returned: %result%
exit /b %errorlevel%

:sub
setlocal enabledelayedexpansion
echo Arg1=%1 Arg2=%~2
endlocal
goto :eof

:sub_return
set "%~1=value from subroutine"
goto :eof

:usage
echo Usage: %~nx0 [/help] [file...]
echo   /help    Show this message
exit /b 0

:two
echo exited with two
exit 2
:: Redirection and piping
type nul > empty.txt
echo data>>log.txt
echo data 2>nul
echo data 1>&2
dir nonexistent 2>&1 | findstr /i "not found"
(echo line1 & echo line2) > multi.txt
> out.txt echo redirect first
< in.txt more
more +5 < big.txt
type file.txt | sort /r | more
:: Misc built-ins
assoc .bat=batfile
break
cd /d D:\data
chdir ..
cmd /?
date /t
time /t
dir /a:d /o:-s /s /b *.log
doskey ll=dir /w $*
endlocal
ftype batfile="%SystemRoot%\system32\cmd.exe" /c "%1" %*
label C:
mklink /d link target
mklink /h hard file
path
pushd \\server\share
rem Done
set errorlevel=
setlocal disabledelayedexpansion
start "title" /b /wait /d "%CD%" cmd /c exit 0
subst X: C:\work
vol
verify on

:: ── Modern Windows commands and cmd.exe features ────────────────────
:: Built-in dynamic variables
echo %=ExitCode% %=ExitCodeAscii% %=C:% %__CD__% %__APPDIR__% %CD% %CMDCMDLINE%
echo %ERRORLEVEL% %RANDOM% %TIME% %DATE% %CMDEXTVERSION% %DIRCMD% %COPYCMD%

:: Tools shipped with Windows 10/11
where /q git && echo git found
where /r C:\Tools *.exe
curl -sSfL -o "%TEMP%\download.zip" https://example.com/archive.zip
tar -xf "%TEMP%\download.zip" -C "%TEMP%\extracted"
tar -czf "%DROP%\backup.tar.gz" -C "%ROOT%" src
winget install --id Example.Tool -e --silent
wsl.exe --list --verbose
wsl -d Ubuntu -- ls -la
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%build.ps1" -Config %CONFIG%
pwsh -NoLogo -Command "Get-ChildItem | Measure-Object"
setx EXAMPLE_HOME "%ROOT%" /m
setx PATH "%PATH%;%ROOT%bin"
icacls "%DROP%" /grant Users:(OI)(CI)R /t
net use Z: \\server\share /persistent:no
net user
sc query Spooler
sc stop Spooler
bcdedit /enum
cipher /w:C:\
compact /c /s:"%DROP%"
fsutil file createnew "%TEMP%\blob.bin" 1048576
certutil -hashfile "%DROP%\b.txt" SHA256
certutil -encode in.bin out.b64
expand -r archive.cab "%TEMP%"
clip < files.txt
findstr /c:"exact phrase" /s /i *.log
findstr /r /c:"^[A-Z]-[0-9][0-9]*$" stock.csv
forfiles /p "%DROP%" /m *.log /d -30 /c "cmd /c del @path"
getmac /fo csv /nh
hostname
ipconfig /all
nslookup example.com
ping -n 1 -w 500 192.0.2.1 >nul
tracert -d example.com
robocopy "%ROOT%src" "%DROP%\src" /E /Z /R:2 /W:5 /LOG+:"%TEMP%\copy.log" /TEE /XD .git /XF *.tmp
reg add HKCU\Software\Acme /v Setting /t REG_SZ /d "value" /f
reg export HKCU\Software\Acme "%TEMP%\acme.reg" /y
schtasks /create /tn "Nightly" /tr "\"%ROOT%run.bat\"" /sc daily /st 02:00 /rl highest /f
systeminfo | findstr /b /c:"OS Name"
whoami /groups /fo list
cmd /d /s /c "echo hello"
start "" /affinity 3 /high "%ProgramFiles%\Tool\tool.exe"
start "" ms-settings:privacy
start "" https://example.com

:: Parenthesised blocks with delayed expansion and nested quotes
set "count=0"
for /f "usebackq delims=" %%L in ("%ROOT%list.txt") do (
    set /a count+=1
    set "line=%%L"
    if "!line:~0,1!"=="#" (
        echo Comment #!count!: !line!
    ) else if "!line!"=="" (
        echo Blank
    ) else (
        echo Entry !count!: !line!
    )
)

:: Argument parsing with shift loop
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--verbose" (set "VERBOSE=1" & shift & goto :parse_args)
if /i "%~1"=="--output" (set "OUTPUT=%~2" & shift & shift & goto :parse_args)
if "%~1:~0,2%"=="--" (echo Unknown option %~1 & exit /b 2)
set "FILES=%FILES% %~1"
shift
goto :parse_args
:args_done

:: Admin check, self-elevation, and error handling idioms
net session >nul 2>&1 || (echo Administrator rights required & exit /b 5)
fltmc >nul 2>&1 && echo elevated
command1 && command2 || command3
(command1 & command2) && echo both ran
copy a.txt b.txt >nul 2>&1 && (echo copied) || (echo copy failed & exit /b 1)
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

:: Here-document style output via parenthesised echo, and string tricks
(
    echo @echo off
    echo echo generated script
    echo exit /b 0
) > "%TEMP%\generated.bat"
set "str=Hello, World"
set "len=0"
:strlen_loop
if not "!str:~%len%,1!"=="" (set /a len+=1 & goto :strlen_loop)
echo Length: %len%
echo %str:Hello=Goodbye% %str:~7% %str:~-5% %str:~0,-7%
set "upper=%str%"
for %%c in (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z) do set "upper=!upper:%%c=%%c!"

:: Percent-encoded and special characters in set /a, with grouping
set /a "a=1, b=2, c=a+b, d=c*c, e=d/2, f=d%%3, g=c<<2, h=(a|b)&c, i=a^b"
set /a "j=(1+2)*(3+4)"
set /a result=%a%+%b%
set /a "k = ~0"

:: Redirect handles 3-9, and appending stderr to a file
call :noisy 3>handle3.txt 4>&1
(call :noisy) 2>>errors.log
echo to-handle-9 9>nul

:: Exit with explicit codes
exit /b 0
