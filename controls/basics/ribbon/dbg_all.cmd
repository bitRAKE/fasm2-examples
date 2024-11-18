@echo off
setlocal EnableExtensions

REM Compile ribbon first to make availible constants created.

if not exist %~n0.rc (
  set UICC="C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x86\uicc.exe"
  %UICC% %~n0.xml %~n0.bin /header:%~n0.h /res:%~n0.rc >>%~n0.log
)

REM change string resource reference into a number
echo #define APPLICATION_RIBBON 1 >>%~n0.h

if not exist %~n0.res (
    RC %~n0.rc >>%~n0.log
)
if not exist impl_X_IUnknown.obj (
  call ..\..\..\bin\fasm2.cmd -e 50 impl_X_IUnknown.asm
)

if [%1] NEQ [] (
  if not exist impl_Xd_IUIApplication.obj (
    call ..\..\..\bin\fasm2.cmd -e 50 -i "DEBUG:=1" impl_Xd_IUIApplication.asm
  )
  if not exist impl_Xd_IUICommandHandler.obj (
    call ..\..\..\bin\fasm2.cmd -e 50 -i "DEBUG:=1" impl_Xd_IUICommandHandler.asm
  )
  if not exist impl_X_IUIEventLogger.obj (
    call ..\..\..\bin\fasm2.cmd -e 50 impl_X_IUIEventLogger.asm
  )
  if not exist _wait_for_key.obj (
    call ..\..\..\bin\fasm2.cmd -e 50 _wait_for_key.asm
  )
  if not exist debug.obj (
    call ..\..\..\bin\fasm2.cmd -e 50 -i "DEBUG:=1" debug.asm
  )
  call ..\..\..\bin\fasm2.cmd -e 50 -i "DEBUG:=1" %~n0.asm
  link @%~n0.response "/SUBSYSTEM:CONSOLE,6.02" ^
	%~n0.obj %~n0.res ^
	impl_X_IUnknown.obj ^
	impl_Xd_IUIApplication.obj ^
	impl_Xd_IUICommandHandler.obj ^
	impl_X_IUIEventLogger.obj ^
	_wait_for_key.obj ^
	debug.obj
) else (
  if not exist impl_X_IUIApplication.obj (
    call ..\..\..\bin\fasm2.cmd -e 50 impl_X_IUIApplication.asm
  )
  if not exist impl_X_IUICommandHandler.obj (
    call ..\..\..\bin\fasm2.cmd -e 50 impl_X_IUICommandHandler.asm
  )
  call ..\..\..\bin\fasm2.cmd -e 50 %~n0.asm
  link @%~n0.response "/SUBSYSTEM:WINDOWS,6.02" ^
	%~n0.obj %~n0.res ^
	impl_X_IUnknown.obj ^
	impl_X_IUIApplication.obj ^
	impl_X_IUICommandHandler.obj
)

REM any command option preserves build artifacts
if [%1] NEQ [] goto:eof

if %errorlevel% EQU 0 (
	del %~n0.bin
	del %~n0.h
	del %~n0.rc

	del %~n0.response
	del %~n0.obj

	del %~n0.res
)
