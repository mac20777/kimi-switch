@echo off
rem CMD / PowerShell entry point for kimi-switch.
rem The real logic lives in the bash script next to this file; here we just
rem forward the call to Git Bash. WSL bash.exe (System32) must NOT be used --
rem its filesystem layout is incompatible with native Windows programs.
setlocal
set "BASH="

rem 1) Well-known Git for Windows install locations
if exist "%ProgramFiles%\Git\bin\bash.exe" set "BASH=%ProgramFiles%\Git\bin\bash.exe"
if not defined BASH if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" set "BASH=%ProgramFiles(x86)%\Git\bin\bash.exe"
if not defined BASH if exist "%LocalAppData%\Programs\Git\bin\bash.exe" set "BASH=%LocalAppData%\Programs\Git\bin\bash.exe"

rem 2) Derive from git.exe on PATH (covers custom drives like D:\...\Git)
if not defined BASH (
    for /f "delims=" %%G in ('where git 2^>nul') do (
        if not defined BASH if exist "%%~dpGbash.exe" set "BASH=%%~dpGbash.exe"
        if not defined BASH if exist "%%~dpG..\bin\bash.exe" set "BASH=%%~dpG..\bin\bash.exe"
    )
)

rem 3) Fall back to bash.exe on PATH, skipping WSL (System32)
if not defined BASH (
    for /f "delims=" %%B in ('where bash 2^>nul') do (
        if not defined BASH (
            echo %%B | findstr /i /c:"\Windows\System32\" >nul || set "BASH=%%B"
        )
    )
)

if not defined BASH (
    echo Error: Git Bash not found. Install Git for Windows, or run kimi-switch inside Git Bash directly. 1>&2
    exit /b 1
)
rem Tell the script the caller is a native Windows shell, so commands that
rem print paths (e.g. `ks dir`, used with cd) emit D:\... instead of /d/...
set "KS_VIA_CMD=1"
"%BASH%" "%~dp0kimi-switch" %*
exit /b %ERRORLEVEL%
