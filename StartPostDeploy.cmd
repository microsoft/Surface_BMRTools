@echo off

set ScriptFolder=%~dp0

rem call ResetPolicy.cmd first if exists
IF EXIST "%ScriptFolder%ResetPolicy.cmd" (
    echo ResetPolicy.cmd exists: %ScriptFolder%ResetPolicy.cmd
    cmd /c %ScriptFolder%ResetPolicy.cmd
) ELSE (
    echo ResetPolicy.cmd does not exist: %ScriptFolder%ResetPolicy.cmd
)

echo Finding the OS location
rem if testing these for loops locally, replace %% with %
rem Define %TARGETOS% as the Windows folder (This later becomes C:\Windows) 
for /F "tokens=1,2,3 delims= " %%A in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\RecoveryEnvironment" /v TargetOS') DO SET TARGETOS=%%C

rem Define %TARGETOSLETTER% as the Windows partition (This later becomes C but may be W or something else while in WinRE after recovery image deployment )
for /F "tokens=1 delims=:" %%A in ('Echo %TARGETOS%') DO SET TARGETOSLETTER=%%A

REM set path to %~n0.ps1
set "PSSCRIPT=%~dpn0.ps1"
echo PSSCRIPT set to %PSSCRIPT%

REM test for PSSCRIPT path to exist
if exist "%PSSCRIPT%" (
    echo %~n0.ps1 exists: %PSSCRIPT%
    if exist "%ScriptFolder%pwsh\pwsh.exe" (
        echo pwsh.exe exists: %ScriptFolder%pwsh\pwsh.exe
        REM call %~n0.ps1 with pwsh.exe
        %ScriptFolder%pwsh\pwsh.exe -ExecutionPolicy Bypass -NonInteractive -Command "& '%PSSCRIPT%' -OSLetter '%TARGETOSLETTER%'"
    ) else (
        echo pwsh.exe does not exist: %ScriptFolder%pwsh\pwsh.exe
    )
) else (
    echo %~n0.ps1 does not exist: %PSSCRIPT%
)

exit /b 0