@echo off

REM	Resolve fasm2 environment with fallback options:
REM		- favor preconfiguration, existing or path variable
REM		- find fixed location
REM		- fallback on command processor, not found

if not "%fasm2%"=="" goto :found

for %%I in (fasm2.cmd) do (
	if exist %%~$$PATH:I (
		set fasm2=%%~$$PATH:I
		goto :found
	)
)
if exist c:\fasm2\fasm2.cmd (
	set fasm2=c:\fasm2\fasm2.cmd
) else	set fasm2=fasm2.cmd
:found
