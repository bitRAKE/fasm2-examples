
; minimal control requirements:
;  + no InitCommonControls*, not required when a manifest is present since
;    WinXP - user32.dll will register classes if needed in the present context.
;  + SysAnimate32 will load a resource AVI with the #id title text.
;  + control styling loops the animation
;  + dialog styling puts the window where the mouse is
;
; build with:
;	fasm2 SysAnimate32.asm
;	rc SysAnimate32.rc
;	link @SysAnimate32.response SysAnimate32.obj SysAnimate32.res

include 'windows.g'
public WinMainCRTStartup
:WinMainCRTStartup:
	pop rax ; no return
	DialogBoxIndirectParamW __ImageBase, & AnimationDialog, 0, & AnimationDlgProc
	ExitProcess rax
	jmp $

:AnimationDlgProc:
	cmp edx, WM_CLOSE
	jnz @F

	enter .frame, 0
	EndDialog rcx, 0
	leave

@@:	xor eax, eax
	retn


BLOCK COFF.4.CONST

	AnimationDialog DLGTEMPLATEEX title: "Assemble-time SysAnimate32",\
		exStyle: WS_EX_TOOLWINDOW,\
		style: DS_CENTERMOUSE or DS_SETFOREGROUND or DS_NOIDLEMSG\
			or WS_POPUP or WS_VISIBLE or WS_CAPTION or WS_THICKFRAME,\
		cx: 256, cy: 64, pointsize: 9, typeface: "Segoe UI"

	DLGITEMTEMPLATEEX title: "#1", id: -1, windowClass: "SysAnimate32",\
		style: ACS_CENTER or ACS_TRANSPARENT or ACS_AUTOPLAY\
			or WS_BORDER or WS_TABSTOP or WS_VISIBLE or WS_CHILD,\
		cx: 256, cy: 64

END BLOCK

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
	db "/MANIFESTDEPENDENCY:""type='Win32' name='Microsoft.Windows.Common-Controls' version='6.0.1.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'""",10
	db 'kernel32.lib',10
	db 'user32.lib',10
	db 'comctl32.lib',10
end virtual
