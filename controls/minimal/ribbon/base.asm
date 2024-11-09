include 'windows.g'
include 'kuser_shared_data.g'
include 'winerror.g'
include 'UIRibbon.g'

public g_hWndMain

BLOCK COFF.64.DATA
	wcex WNDCLASSEX cbSize: sizeof wcex,\
		lpfnWndProc: WndProcW,\
		hInstance: __ImageBase,\
		lpszClassName: g_class_name,\
		hbrBackground: 0


	; start cursor position and monitor
	g_init_monitor		MONITORINFOEXW cbSize: sizeof MONITORINFOEXW
	g_init_cursor_point	POINT

	g_hWndMain	dq ?

	g_class_name du "bitRAKE",0
	g_window_title equ g_class_name

; :TODO:
	Settings.main.width	dd 640
	Settings.main.hieght	dd 768
END BLOCK

;-------------------------------------------------------------------------------
public WinMainCRTStartup as "WinMainCRTStartup" ; default linker entry
:WinMainCRTStartup:
	virtual at rbp+16
		.msg		MSG
		.local := ($-$$+15) and (-16)
				rq 2
	; shadow-space:
		.rc		RECT
	end virtual
	enter .frame + .local, 0
	mov [.msg.wParam], 1 ; EXIT_FAILURE

; commandline
; load and respond to settings

	cmp [dword ProcessorFeatures + PF_AVX2_INSTRUCTIONS_AVAILABLE], 0
	jz .Fatal		; Y: insufficient processor support

; The ribbon control requires single threaded apartment.
;	OleInitialize 0 ; calls CoInitializeEx internally
	CoInitializeEx NULL, COINIT_APARTMENTTHREADED ; single-threaded
;	CoInitializeEx NULL, COINIT_MULTITHREADED ; free-threading, doesn't work
	test eax, eax		; HRESULT
	js .Fatal		; Y: conflicting concurrency model elsewhere
;	InitCommonControls	; not needed, if manifest

;	SetProcessDPIAware ; BOOL

; Lacking in configuration, position the window under the mouse cursor,
; but completely within the dimensions of the monitor containing the cursor:
; ...
	GetCursorPos & g_init_cursor_point
	; :note: point structure data is pass in register
	MonitorFromPoint qword [g_init_cursor_point], MONITOR_DEFAULTTONEAREST
	xchg rcx, rax ; hMonitor
	GetMonitorInfoW rcx, & g_init_monitor

; :todo: need some sensible rules to place window
;	- if position is invalid, center window under cursor
;	- if size is invalid,
;		- static default size
;		- ? ratio of monitor

	vmovq xmm0, qword [g_init_monitor.rcMonitor.right]
	vmovq xmm1, qword [g_init_monitor.rcMonitor.left]
	vmovq xmm2, qword [Settings.main.width]
	vpsubd xmm0, xmm0, xmm1		; monitor: width, height
	vpsubd xmm0, xmm0, xmm2
	vpsrad xmm0, xmm0, 1
	vpaddd xmm1, xmm1, xmm0
	vpaddd xmm2, xmm1, xmm2
	vmovq qword [.rc.left], xmm1	; window: upper left coords
	vmovq qword [.rc.right], xmm2	; window: lower right coords

	AdjustWindowRect & .rc, dword .style, 0, dword .xstyle
	vmovq xmm0, qword [.rc.right]
	vpsubd xmm0, xmm0, xword [.rc.left]
	vmovq qword [.rc.right], xmm0 ; window: width, height


	LoadCursorW NULL, IDC_ARROW
	mov [wcex.hCursor], rax
;	LoadIconW __ImageBase, IDI_APP_MAIN
;	mov [wcex.hIcon], rax
;	LoadIconW __ImageBase, IDI_APP_SMALL
;	mov [wcex.hIconSm], rax

	RegisterClassExW & wcex
	test ax, ax
	jz .Fatal			; Y: unknown program state
	movzx edx, ax ; ATOM

;	WS_EX_CLIENTEDGE	sunken edge
;	WS_EX_STATICEDGE	3D border (no user input)
;	WS_EX_WINDOWEDGE	raised edge
;
;	WS_EX_COMPOSITED	double buffering effects, descendants need WS_EX_TRANSPARENT
;	WS_EX_LAYERED		improve performance and visual effects

	.xstyle	:= WS_EX_APPWINDOW or WS_EX_ACCEPTFILES or WS_EX_LAYERED
	.style	:= WS_OVERLAPPEDWINDOW or WS_CLIPCHILDREN or WS_VISIBLE or WS_SYSMENU or WS_SIZEBOX or WS_CAPTION
	CreateWindowExW .xstyle, rdx, & g_window_title, .style,\
		[.rc.left], [.rc.top], [.rc.right], [.rc.bottom],\
		0, 0, __ImageBase, 0
	test rax, rax
	jz .Fatal			; Y: unknown program state
	if .xstyle and WS_EX_LAYERED ; layered windows require, regardless of WS_VISIBLE
		SetLayeredWindowAttributes rax, 0, 255, LWA_ALPHA ; opaque
	end if

;	ShowWindow [g_hWndMain], 10 ; SW_SHOWDEFAULT
;	UpdateWindow [g_hWndMain]
	jmp @F
.message_loop:
	TranslateMessage & .msg
	DispatchMessageW & .msg
@@:	GetMessageW & .msg, 0, 0, 0, 0
	test eax, eax ; BOOL or -1
	jg .message_loop
	CoUninitialize
;	OleUninitialize
.Fatal:
	ExitProcess [.msg.wParam]
	jmp $

;------------------------------------------------------------------------------
; We can generate a response file for use with the linker. This is better than
; using a '.drectve' section as all the commands are allowed. :-)
virtual as "response"
RESPONSE::
	db '/NOLOGO',10
;	db '/VERBOSE',10,'/TIME+',10	; use to debug process

; Create unique binary using image version and checksum:
	repeat 1,T:__TIME__ shr 16,t:__TIME__ and 0xFFFF
		db '/VERSION:',`T,'.',`t,10
	end repeat
	db '/RELEASE',10		; set program checksum in header

	db '/FIXED',10			; no relocation information
	db '/IGNORE:4281',10		; ASLR doesn't happen for /FIXED!
	db '/BASE:0x7FFF0000',10	; above KUSER_SHARED_DATA
;	db '/BASE:0x10000',10
	db '/SUBSYSTEM:CONSOLE,6.02',10	; Win8+
	db '/NODEFAULTLIB',10		; all dependencies explicit, below

	db '/SUBSYSTEM:WINDOWS,6.02',10
	db '/MANIFEST:EMBED',10
	db "/MANIFESTUAC:""level='asInvoker' uiAccess='false'""",10
	db "/MANIFESTDEPENDENCY:""type='Win32' name='Microsoft.Windows.Common-Controls' version='6.0.0.0' processorArchitecture='*' publicKeyToken='6595b64144ccf1df' language='*'""",10
;/MANIFEST
;/ManifestFile:"x64\Release\SimpleRibbon.exe.intermediate.manifest" 

;	db 'kernel32.lib',10
	db 'user32.lib',10
;		wsprintfW
;	db 'ole32.lib',10
;	db 'advapi32.lib',10

	db 'OneCoreUAP.lib',10

end virtual
