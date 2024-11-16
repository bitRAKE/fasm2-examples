@echo off

REM Compile ribbon first to make availible constants created.

set UICC="C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x86\uicc.exe"
%UICC% %~n0.xml %~n0.bin /header:%~n0.h /res:%~n0.rc >>%~n0.log

REM change string resource reference into a number
echo #define APPLICATION_RIBBON 1 >>%~n0.h

call ..\..\..\bin\fasm2.cmd -e 50 impl_X_IUnknown.asm
call ..\..\..\bin\fasm2.cmd -e 50 impl_X_IUIApplication.asm
call ..\..\..\bin\fasm2.cmd -e 50 impl_X_IUICommandHandler.asm
call ..\..\..\bin\fasm2.cmd -e 50 %~n0.asm

RC %~n0.rc >>%~n0.log

link @%~n0.response %~n0.obj %~n0.res ^
	impl_X_IUnknown.obj ^
	impl_X_IUIApplication.obj ^
	impl_X_IUICommandHandler.obj

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
