
; The most basic ribbon control.
;	- connecting parent window to ribbon framework
;	- loading ribbon binary resource
;	- no controls

include 'base.asm' ; main window startup

virtual RESPONSE ; add to linker instructions ...
	db 'app.obj',10 ; First object defines the default EXE name!

	; Must be linked with implementation of IUIApplication.
	db 'impl_IUIApplication.obj',10

	; Must be linked with implementation of IUICommandHandler.
	db 'impl_IUICommandHandler.obj',10

	; app.ribbon XML compiled into resource binary
	db 'ribbon.res',10
end virtual

extrn static__IUIApplication ; static application COM object

BLOCK COFF.8.BSS ; application global
	g_pFramework	IUIFramework
END BLOCK


; default DefWindowProcW handling:
;	WM_CLOSE	DestroyWindow
WndProcW:
	iterate message, WM_GETMINMAXINFO,WM_ERASEBKGND,WM_KEYDOWN,WM_DESTROY,WM_CREATE
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
	SendMessageW rcx, WM_CLOSE, 0, 0
.processed:
	xor eax, eax
	leave
	retn


.WM_ERASEBKGND:
	mov eax, 1 ; background updated
;	xor eax, eax ; use default processing
	retn


.WM_DESTROY: ; n/a, n/a ; window already closed
	enter 32, 0

	IUIFramework__Destroy [g_pFramework]
	IUIFramework__Release [g_pFramework]
;	IUIApplication__Release [g_pApplication] ; doesn't do anything

	PostQuitMessage 0 ; return status
	jmp .processed


.WM_GETMINMAXINFO: ; n/a, MINMAXINFO
; Preventing ribbon control from disappearing.
; :Note: The exact dimensions are based on window decoration.
	mov [r9 + MINMAXINFO.ptMinTrackSize.x], 301
	mov [r9 + MINMAXINFO.ptMinTrackSize.y], 251
	xor eax,eax
	retn



:WndProcW.WM_CREATE:
	enter .frame, 0
	virtual at rbp+16
		.hWnd	dq ?
	end virtual
	mov [.hWnd], rcx

; Ambiguity in threading might require establishing the thread COM model:
;	CoInitializeEx NULL, COINIT_APARTMENTTHREADED

; The class only supports one interface:
;	CoCreateInstance & CLSID_UIRibbonFramework, NULL, CLSCTX_INPROC_SERVER, & IID_IUIFramework, & g_pFramework
	CoCreateInstance & CLSID_UIRibbonFramework, NULL, CLSCTX_INPROC_SERVER, & IID_IUnknown, & g_pFramework
	test eax, eax ; HRESULT
	js .fail

	IUIFramework__Initialize [g_pFramework], [.hWnd], & static__IUIApplication
	test eax, eax ; HRESULT
	js .fail

	IUIFramework__LoadUI [g_pFramework], __ImageBase, W "APP_RIBBON"
	test eax, eax ; HRESULT
	jns WndProcW.processed

.fail:	or rax, -1 ; unable to create window
	leave
	retn
