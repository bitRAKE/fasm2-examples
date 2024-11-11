include 'base.asm' ; boilerplate, main window startup
include "import_c_define.g",THE_FILE equ "app.rc"

extrn static__IUIApplication ; static application COM object
extrn g_uRibbonHeight:4

BLOCK COFF.8.BSS ; application global
	g_pFramework	IUIFramework
END BLOCK

; default DefWindowProcW handling:
;	WM_CLOSE	DestroyWindow
WndProcW:
	iterate message, WM_GETMINMAXINFO,WM_ERASEBKGND,\;WM_SIZE,\
		WM_KEYDOWN,WM_DESTROY,WM_CREATE
		cmp edx, message
		jz .message
	end iterate
.default:
	extrn "__imp_DefWindowProcW" as .DefWindowProcW
	jmp qword [.DefWindowProcW]


.WM_KEYDOWN:
	cmp r8d, VK_ESCAPE
	jnz .default
	enter 32, 0
	; respect window message hierarchy: WM_CLOSE -> WM_DESTROY
;	SendMessageW rcx, WM_CLOSE, 0, 0 ; don't send to window
	PostMessageW rcx, WM_CLOSE, 0, 0 ; relax, put in queue for GetMessage
.processed:
	xor eax, eax
	leave
	retn


.WM_ERASEBKGND: ; R8:hDC, R9:(not used)
;	mov eax, 1 ; background updated
	xor eax, eax ; use default processing
	retn


.WM_DESTROY: ; n/a, n/a ; window already closed
	enter 32, 0
	DisableRibbonControlLogging
	IUIFramework__Destroy [g_pFramework]
	IUIFramework__Release [g_pFramework]
	PostQuitMessage 0 ; return status
	jmp .processed


.WM_GETMINMAXINFO: ; n/a, MINMAXINFO
; Just preventing ribbon control from disappearing.
; :TODO: Set more sensible values befitting the application.
; :Note: The exact dimensions are based on window decoration.
	mov [r9 + MINMAXINFO.ptMinTrackSize.x], 301
	mov [r9 + MINMAXINFO.ptMinTrackSize.y], 251
	xor eax,eax
	retn

if 0
:WndProcW.WM_SIZE:
	enter .frame, 0
	virtual at rbp+16
		.rect	RECT
	end virtual
	GetClientRect rcx, & .rect
	mov rcx, [g_Debug.hWnd]
	jrcxz @F
	mov r8d, [g_uRibbonHeight]
	test r8d, r8d
	js @F
; lower top edge to account for ribbon size, reduce height by ribbon size
	sub [.rect.bottom], r8d
	MoveWindow rcx, 0, r8, [.rect.right], [.rect.bottom], TRUE
@@:	jmp WndProcW.processed
end if


:WndProcW.WM_CREATE:
	enter .frame, 0
	mov [g_hWndMain], rcx

; Ambiguity in threading might require establishing the thread COM model:
;	CoInitializeEx NULL, COINIT_APARTMENTTHREADED

	CoCreateInstance & CLSID_UIRibbonFramework, NULL, CLSCTX_INPROC_SERVER, & IID_IUIFramework, & g_pFramework
; Could assume primary interface:
;	CoCreateInstance & CLSID_UIRibbonFramework, NULL, CLSCTX_INPROC_SERVER, & IID_IUnknown, & g_pFramework
	test eax, eax ; HRESULT
	js .fail

	IUIFramework__Initialize [g_pFramework], [g_hWndMain], & static__IUIApplication
	test eax, eax ; HRESULT
	js .fail

	IUIFramework__LoadUI [g_pFramework], __ImageBase, APPLICATION_RIBBON
	test eax, eax ; HRESULT
	js .fail

; Begin event logging to console.
	EnableRibbonControlLogging [g_pFramework], [hOutput]

	jmp WndProcW.processed

.fail:	or rax, -1 ; unable to create window
	leave
	retn
