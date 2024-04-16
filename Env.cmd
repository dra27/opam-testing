@setlocal
@echo off

rem windows-initial battery testing - test environment setup

set ROOT=C:\Testing
set CYGWIN_SETUP=setup-2.931-x86_64.exe
set MSYS2_SETUP=msys2-base-x86_64-20240113.sfx.exe

if not exist %ROOT% md %ROOT%

rem Download installers - destroy existing installations if installers are
rem downloaded.
if not exist %ROOT%\%CYGWIN_SETUP% (
  if exist %ROOT%\cygwin64 rd /s/q %ROOT%\cygwin64
  curl -sLo %ROOT%\%CYGWIN_SETUP% https://www.cygwin.com/setup-x86_64.exe
) else (
  if exist %ROOT%\setup-x86_64.exe del %ROOT%\setup-x86_64.exe
  curl -sLo %ROOT%\setup-x86_64.exe -z %ROOT%\%CYGWIN_SETUP% https://www.cygwin.com/setup-x86_64.exe
  if exist %ROOT%\setup-x86_64.exe (
    echo New setup downloaded - Env.cmd needs updating with version
    echo Executable left in %ROOT%\setup-x86_64.exe
    exit /b 1
  )
)

if not exist %ROOT%\%MSYS2_SETUP% (
  if exist %ROOT%\msys64 rd /s/q %ROOT%\msys64
  curl -sLo %ROOT%\%MSYS2_SETUP% https://github.com/msys2/msys2-installer/releases/download/%MSYS2_SETUP:~-16,4%-%MSYS2_SETUP:~-12,2%-%MSYS2_SETUP:~-10,2%/%MSYS2_SETUP%
)

if not exist %ROOT%\setup.xz (
  curl -sLo %ROOT%\setup.xz https://mirrorservice.org/sites/sourceware.org/pub/cygwin/x86_64/setup.xz
) else (
  if exist %ROOT%\setup.xz.tmp del %ROOT%\setup.xz.tmp
  curl -sLo %ROOT%\setup.xz.tmp -z %ROOT%\setup.xz https://mirrorservice.org/sites/sourceware.org/pub/cygwin/x86_64/setup.xz
  if exist %ROOT%\setup.xz.tmp (
    del %ROOT%\setup.xz
    ren %ROOT%\setup.xz.tmp setup.xz
  ) else (
    goto SkipCygwin
  )
)

rem Install/upgrade Cygwin
set CYGWIN_FLAG=
if exist %ROOT%\cygwin64\bin\cygwin1.dll set CYGWIN_FLAG=--upgrade-also
%ROOT%\setup-2.931-x86_64.exe --root %ROOT%\cygwin64 --arch x86_64 --only-site --site https://mirrorservice.org/sites/sourceware.org/pub/cygwin --local-package-dir %ROOT%\cache --no-admin --no-desktop --no-replaceonreboot --no-shortcuts --no-startmenu --no-write-registry --quiet-mode noinput %CYGWIN_FLAG%

:SkipCygwin
%ROOT%\cygwin64\bin\bash -lc "uname -a"

rem Install/update MSYS2
if not exist %ROOT%\msys64\usr\bin\msys-2.0.dll (
  %ROOT%\%MSYS2_SETUP% -y -o%ROOT%\
  %ROOT%\msys64\usr\bin\bash -lc "uname -a"
)
%ROOT%\msys64\usr\bin\bash -lc "pacman --noconfirm --overwrite '*' -Syuu"
taskkill /F /FI "MODULES eq msys-2.0.dll"
%ROOT%\msys64\usr\bin\bash -lc "pacman --noconfirm --overwrite '*' -Syuu"
%ROOT%\msys64\usr\bin\bash -lc "uname -a"
