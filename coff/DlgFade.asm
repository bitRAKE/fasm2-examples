if 0

; the fade in/out is a progression to/from the user preferred opacity
user_preferences:
~	.effects_duration dd ? ; ms
~	.opacity db ? ; 0xFF = opaque

.defaults:
	mov [.effects_duration], 500
	mov [.opacity], 0xFF
	retn

	; approximate step delay:

	; start is zero opacity
	movzx ecx, [.opacity] ; steps needed to reach perference
	mov eax, [.effects_duration]
	xor edx, edx
	div ecx
	mov edx, 1
	test eax, eax
	cmovz eax, edx ; min(1,ms/step)
	mov [.dtime], eax

	; how much opacity change per step?
end if


include 'AppWindow.g'

tdlg	dd WS_CAPTION or WS_POPUP or WS_SYSMENU \
	or DS_CENTER or DS_CENTERMOUSE or DS_MODALFRAME or DS_NOIDLEMSG or DS_SETFOREGROUND or DS_SYSMODAL

	dd WS_EX_TOOLWINDOW or WS_EX_LAYERED
	dw 0,320,240,240,160
	dd 0
	du 'layered dlg',0
	db 0Fh,0FFh,0Fh,0A6h,0


;------------------------------------------------------------------------------
WinMainCRTStartup: fastcall?.frame = 0
	pop rax ; no return
	DialogBoxIndirectParamA dword __ImageBase, dword tdlg, 0, dword DialogProc ; param unused
	ExitProcess 0
	.frame := fastcall?.frame


DialogProc: fastcall?.frame = 0
	virtual at rbp+16 ; use shadow space
		.hDlg		dq ?
	end virtual
	enter .frame, 0
	mov [.hDlg], rcx
	iterate uMsg, WM_CLOSE,WM_INITDIALOG
		cmp edx, uMsg
		jz .uMsg
	end iterate
	xor eax, eax
	leave
	retn

.WM_INITDIALOG:
;	GetWindowLongPtrA [.hDlg], GWL_EXSTYLE
;	or rax, WS_EX_LAYERED
;	xchg r8, rax
;	SetWindowLongPtrA [.hDlg], GWL_EXSTYLE, r8
	jmp @F ; no set focus

.WM_CLOSE:
	bts [.hDlg], 63 ; fade out
@@:	CreateThread 0, 0, dword fade_inout, [.hDlg], 0, 0
	xor eax, eax
	leave
	retn
	.frame := fastcall?.frame


fade_inout: fastcall?.frame = 0
	virtual at rbp+16 ; use shadow space
		.hDlg		dq ?
		.bAlpha		db ?
		.direction	db ?
		assert $-$$ < 33
	end virtual
	enter .frame, 0
	btr rcx, 63 ; mode flag
	sbb eax, eax
	mov [.hDlg], rcx
	mov dword [.bAlpha], eax
.fading:
	SetLayeredWindowAttributes [.hDlg], 0, [.bAlpha], LWA_ALPHA
	Sleep 3 ; rcx

	test [.direction], -1
	jnz .out
	add [.bAlpha], 1
	jnc .fading
	leave
	retn
.out:
	sub [.bAlpha], 1
	jnc .fading
	EndDialog [.hDlg], 0
	leave
	retn
	.frame := fastcall?.frame

;------------------------------------------------------------------------------
; We can generate a response file for use with the linker. This is better than
; using a '.drectve' section as all the commands are allowed. :-)
virtual as "response"
	db '/NOLOGO',10
;	db '/VERBOSE',10 ; use to debug process
	db '/NODEFAULTLIB',10
	db '/BASE:0x10000',10
	db '/DYNAMICBASE:NO',10
	db '/IGNORE:4281',10
	db '/SUBSYSTEM:WINDOWS,6.02',10
	db '/MANIFEST:EMBED',10
	db "/MANIFESTDEPENDENCY:""type='Win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'""",10
	db 'OneCoreUAP.Lib',10
end virtual
