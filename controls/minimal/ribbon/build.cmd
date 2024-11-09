@echo off
call ..\..\..\bin\fasm2.cmd impl_IUICommandHandler.asm
call ..\..\..\bin\fasm2.cmd impl_IUIApplication.asm
call ..\..\..\bin\fasm2.cmd app.asm

set UICC="C:\Program Files (x86)\Windows Kits\10\bin\10.0.22621.0\x86\uicc.exe"
%UICC% app.ribbon ribbon.bin /header:ribbon.h /res:ribbon.rc /name:app

RC ribbon.rc

link @app.response

if [%1] NEQ [] goto:eof

if %errorlevel% EQU 0 (
	del *.obj
	del ribbon.*
	del app.response
)
