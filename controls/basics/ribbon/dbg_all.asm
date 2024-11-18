; TODO:
;	- ?

include 'windows.g'
include 'winerror.g'
include 'kuser_shared_data.g'
include 'debug.asm' ; consolidated debugging support

; interfaces needed upstream - no ribbon stuff in this file
include 'UIRibbon.g'
public g_hWndMain

APPLICATION_RIBBON := 1
extrn X_IUIApplication ; static application COM interface instance
extrn g_uRibbonHeight:4

BLOCK COFF.64.DATA
	g_class_name du "bitRAKE",0
	g_window_title equ g_class_name
	g_hWndMain	dq ?
	g_pFramework	IUIFramework

	wcex WNDCLASSEX cbSize: sizeof wcex,\
		lpfnWndProc: WndProcW,\
		hInstance: __ImageBase,\
		lpszClassName: g_class_name,\
		hbrBackground: 1+COLOR_WINDOWTEXT
END BLOCK

;-------------------------------------------------------------------------------
; default DefWindowProcW handling:
;	WM_CLOSE	DestroyWindow
WndProcW:
	iterate message, WM_GETMINMAXINFO,\;WM_SIZE,\
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
	PostMessageW rcx, WM_CLOSE, 0, 0 ; relax, put in queue for GetMessage
.processed:
	xor eax, eax
	leave
	retn


.WM_DESTROY: ; n/a, n/a ; window already closed
	enter 32, 0
	DisableRibbonControlLogging ; DEBUG gated
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
	CoCreateInstance & CLSID_UIRibbonFramework, NULL, CLSCTX_INPROC_SERVER,\
		& IID_IUIFramework, & g_pFramework
	test eax, eax ; HRESULT
	js .fail

	IUIFramework__Initialize [g_pFramework], [g_hWndMain], & X_IUIApplication
	test eax, eax ; HRESULT
	js .fail

	IUIFramework__LoadUI [g_pFramework], __ImageBase, APPLICATION_RIBBON
	test eax, eax ; HRESULT
	js .fail

	EnableRibbonControlLogging [g_pFramework], [hOutput] ; DEBUG gated
	jmp WndProcW.processed

.fail:	or rax, -1 ; unable to create window
	leave
	retn

;===============================================================================
;===============================================================================
public TitansGenesis
:TitansGenesis:
	virtual at rbp - .local
		.msg		MSG
		.local := ($-$$+15) and (-16)
	end virtual
	virtual at rbp + 16
		.rc		RECT
		.dwMode		dd ?
		assert $-$$ < 33 ; shadowspace limitation
	end virtual
	enter .frame + .local, 0
	mov [.msg.wParam], 1 ; EXIT_FAILURE

	debug_startup ; DEBUG gated, obviously

	iterate feature, PF_FASTFAIL_AVAILABLE, PF_AVX2_INSTRUCTIONS_AVAILABLE
		cmp [dword ProcessorFeatures + feature], 0
		jz .Fatal ; Y: insufficient processor/windows support
	end iterate

	CoInitializeEx NULL, COINIT_APARTMENTTHREADED ; single-threaded
	test eax, eax		; HRESULT
	js .Fatal		; Y: conflicting concurrency model elsewhere

	LoadCursorW NULL, IDC_ARROW
	mov [wcex.hCursor], rax

	RegisterClassExW & wcex
	test ax, ax
	jz .Fatal			; Y: unknown program state
	movzx edx, ax ; ATOM

	.xstyle	:= WS_EX_APPWINDOW
	.style	:= WS_OVERLAPPEDWINDOW or WS_CLIPCHILDREN or WS_VISIBLE or WS_SYSMENU or WS_SIZEBOX or WS_CAPTION
	mov r11d, CW_USEDEFAULT
	CreateWindowExW .xstyle, rdx, & g_window_title, .style, r11d, r11d, r11d, r11d, 0, 0, __ImageBase, 0
	test rax, rax
	jz .Fatal			; Y: unknown program state
	jmp @F

.message_loop:
	TranslateMessage & .msg
	DispatchMessageW & .msg
@@:	GetMessageW & .msg, 0, 0, 0, 0
	test eax, eax ; BOOL or -1
	jg .message_loop
	CoUninitialize
	if definite DEBUG & DEBUG
		_wait_for_key
	end if ; definite DEBUG & DEBUG
.Fatal:
	ExitProcess [.msg.wParam]
	jmp $


;------------------------------------------------------------------------------
; We can generate a response file for use with the linker. This is better than
; using a '.drectve' section as all the commands are allowed. :-)
virtual as "response"
RESPONSE::
	db '/ENTRY:TitansGenesis',10
	db '/NOLOGO',10
;	db '/VERBOSE',10,'/TIME+',10	; use to debug process

; Create unique binary using image version and checksum:
	repeat 1,T:__TIME__ shr 16,t:__TIME__ and 0xFFFF
		db '/VERSION:',`T,'.',`t,10
	end repeat
	db '/RELEASE',10		; set program checksum in header

	db '/FIXED',10			; no relocation information
	db '/IGNORE:4281',10		; ASLR doesn't happen for /FIXED!
;	db '/BASE:0x7FFF0000',10	; above KUSER_SHARED_DATA
	db '/BASE:0x10000',10

	db '/NODEFAULTLIB',10		; all dependencies explicit, below

	db '/MANIFEST:EMBED',10
	db "/MANIFESTUAC:""level='asInvoker' uiAccess='false'""",10
	db "/MANIFESTDEPENDENCY:""type='Win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'""",10
;/MANIFEST
;/ManifestFile:"x64\Release\SimpleRibbon.exe.intermediate.manifest" 

	db 'kernel32.lib',10
	db 'user32.lib',10
	db 'ole32.lib',10
;	db 'shell32.lib',10
;	db 'advapi32.lib',10
	db 'shlwapi.lib',10

;	db 'OneCoreUAP.lib',10
end virtual
