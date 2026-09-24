@echo off
REM Build the project and copy the artefacts to the drop folder.
setlocal EnableDelayedExpansion

set CONFIG=Release
set DROP=%USERPROFILE%\drops\%DATE:~-4%%DATE:~3,2%%DATE:~0,2%

if not exist "%DROP%" mkdir "%DROP%"

for %%F in (*.csproj) do (
    echo Building %%~nF in %CONFIG% ...
    dotnet build "%%F" -c %CONFIG% || goto :fail
    set /a built+=1
)

echo Built !built! project(s)
xcopy /y /s bin\%CONFIG%\*.dll "%DROP%\" >nul
goto :eof

:fail
echo Build failed with error %ERRORLEVEL% 1>&2
exit /b 1
