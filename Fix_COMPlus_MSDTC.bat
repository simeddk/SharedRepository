@echo off
setlocal EnableDelayedExpansion

title SmartMaker COM+/MSDTC Fix Tool

:: ---- Admin check (no service dependency) ----
whoami /groups 2>nul | find /i "S-1-16-12288" > nul
if %errorlevel% neq 0 (
    echo [ERROR] Administrator privileges required.
    echo Right-click this file and select "Run as administrator".
    pause
    exit /b 1
)

set LOG=%~dp0fix_log.txt
echo [%date% %time%] START > "%LOG%"
echo.
echo ============================================================
echo   SmartMaker COM+/MSDTC Fix Tool
echo   Designed for minimal Windows installations
echo ============================================================
echo.

:: ---- STEP 1: Stop services ----
echo [1/5] Stopping services...
echo --- STEP1 --- >> "%LOG%"
sc stop MSDTC > nul 2>&1
echo   MSDTC stop: !errorlevel! >> "%LOG%"
sc stop COMSysApp > nul 2>&1
echo   COMSysApp stop: !errorlevel! >> "%LOG%"
echo   Done.
echo.

:: ---- STEP 2: Re-register COM+ DLLs ----
echo [2/5] Re-registering COM+ DLLs...
echo --- STEP2 --- >> "%LOG%"
for %%d in (ole32.dll oleaut32.dll comsvcs.dll atl.dll) do (
    if exist "%SystemRoot%\system32\%%d" (
        regsvr32 /s "%SystemRoot%\system32\%%d"
        echo   regsvr32 %%d: !errorlevel! >> "%LOG%"
    ) else (
        echo   regsvr32 %%d: not found (skip) >> "%LOG%"
    )
)
echo   Done.
echo.

:: ---- STEP 3: Enable COM+ features via DISM ----
echo [3/5] Enabling COM+ features...
echo --- STEP3 --- >> "%LOG%"
dism /online /enable-feature /featurename:ComPlusNetworkAccess /NoRestart > nul 2>&1
echo   ComPlusNetworkAccess: !errorlevel! >> "%LOG%"
dism /online /enable-feature /featurename:ComPlusManagement /NoRestart > nul 2>&1
echo   ComPlusManagement: !errorlevel! >> "%LOG%"
echo   Done (0=OK, 3010=restart needed, other=unavailable).
echo.

:: COMSysApp must be running before RegSvcs can access COM+ catalog
net start COMSysApp > nul 2>&1
echo   COMSysApp pre-start: !errorlevel! >> "%LOG%"

:: If COMSysApp still fails to start, log diagnostic info
if !errorlevel! neq 0 (
    echo   [DIAG] COMSysApp service config: >> "%LOG%"
    sc qc COMSysApp >> "%LOG%" 2>&1
    echo   [DIAG] comsvcs.dll path: >> "%LOG%"
    dir "%SystemRoot%\system32\comsvcs.dll" >> "%LOG%" 2>&1
)

:: ---- STEP 4: Re-register .NET EnterpriseServices ----
echo [4/5] Re-registering .NET EnterpriseServices...
echo --- STEP4 --- >> "%LOG%"
set REGSVCS_DONE=0

if exist "%SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\RegSvcs.exe" (
    if exist "%SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\System.EnterpriseServices.dll" (
        "%SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\RegSvcs.exe" "%SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\System.EnterpriseServices.dll" > nul 2>&1
        echo   RegSvcs x64 v4: !errorlevel! >> "%LOG%"
        set REGSVCS_DONE=1
    )
)
if exist "%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\RegSvcs.exe" (
    if exist "%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\System.EnterpriseServices.dll" (
        "%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\RegSvcs.exe" "%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\System.EnterpriseServices.dll" > nul 2>&1
        echo   RegSvcs x86 v4: !errorlevel! >> "%LOG%"
        set REGSVCS_DONE=1
    )
)
if exist "%SystemRoot%\Microsoft.NET\Framework\v2.0.50727\RegSvcs.exe" (
    if exist "%SystemRoot%\Microsoft.NET\Framework\v2.0.50727\System.EnterpriseServices.dll" (
        "%SystemRoot%\Microsoft.NET\Framework\v2.0.50727\RegSvcs.exe" "%SystemRoot%\Microsoft.NET\Framework\v2.0.50727\System.EnterpriseServices.dll" > nul 2>&1
        echo   RegSvcs x86 v2: !errorlevel! >> "%LOG%"
        set REGSVCS_DONE=1
    )
)
if "!REGSVCS_DONE!"=="0" (
    echo   [WARNING] RegSvcs.exe not found. .NET Framework may not be installed.
    echo   WARNING: RegSvcs.exe not found >> "%LOG%"
)
echo   Done.
echo.

:: ---- STEP 5: Restart services ----
echo [5/5] Restarting services...
echo --- STEP5 --- >> "%LOG%"
sc config COMSysApp start= auto > nul 2>&1
echo   COMSysApp config: !errorlevel! >> "%LOG%"
sc config MSDTC start= auto > nul 2>&1
echo   MSDTC config: !errorlevel! >> "%LOG%"
net start COMSysApp > nul 2>&1
echo   COMSysApp start: !errorlevel! >> "%LOG%"
net start MSDTC > nul 2>&1
echo   MSDTC start: !errorlevel! >> "%LOG%"
echo   Done.
echo.

echo [%date% %time%] COMPLETE >> "%LOG%"

echo ============================================================
echo   Fix complete. Please RESTART your PC, then run SmartMaker.
echo   Log: %LOG%
echo   (0=OK, 3010=restart required)
echo ============================================================
echo.
echo Press SPACE or ENTER to close...
powershell -NoProfile -Command "$k=@(32,13);do{$r=$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')}while($k -notcontains $r.VirtualKeyCode)"
