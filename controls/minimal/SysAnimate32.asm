
; minimal control requirements
;
; build with:
;	fasm2 SysAnimate32.asm
;	rc SysAnimate32.rc
;	link @SysAnimate32.response SysAnimate32.obj SysAnimate32.res

include '..\windows.g'
public WinMainCRTStartup
:WinMainCRTStartup:
	pop rax ; no return
{const:8} .iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_ANIMATE_CLASS
	InitCommonControlsEx dword .iccx
	test eax, eax ; BOOL
	setz al ; EXIT_FAILURE on FALSE
	jz @F
	DialogBoxParamW dword __ImageBase, 1, 0, dword AnimationDlgProc
@@:	ExitProcess rax

:AnimationDlgProc:
	cmp edx, WM_CLOSE
	jnz @F

	enter .frame, 0
	EndDialog rcx, 0
	leave

@@:	xor eax, eax
	retn

;------------------------------------------------------------------------------
; We can generate a response file for use with the linker. This is better than
; using a '.drectve' section as all the commands are allowed. :-)
;
; Of course, we could add the object files for all examples here. Yet, build
; optimization benfits from defining dependancies in the makefile.
virtual as "response"
	db '/NOLOGO',10
;	db '/VERBOSE',10 ; use to debug process
	db '/NODEFAULTLIB',10
	db '/BASE:0x10000',10
	db '/DYNAMICBASE:NO',10
	db '/IGNORE:4281',10 ; bogus warning to scare people away
	db '/SUBSYSTEM:WINDOWS,6.02',10
	db '/MANIFEST:EMBED',10
	db "/MANIFESTDEPENDENCY:""type='Win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'""",10
	db 'kernel32.lib',10
	db 'user32.lib',10
	db 'comctl32.lib',10
end virtual
