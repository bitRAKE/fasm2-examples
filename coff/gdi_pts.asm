
; Using the GDI coordinate system, we can adapt fixed polygon data
; to a variable sized window.
; https://learn.microsoft.com/en-us/windows/win32/gdi/invalidating-the-client-area

include 'AppWindow.g'

struc(named) POLYLINE points&
	local count
	align 8
	dd ?,count ; for runtime use
	label named:count ; for assemble-time use
	iterate <X,Y>, points
		.% POINT X,Y
	end iterate
	count := ($ - named) shr 3
end struc
POLYLINE.POINTS := -4

{const}	aptTriangle	POLYLINE 50,5, 93,92, 7,92, 50,5
{const}	aptSquare	POLYLINE 10,10, 90,10, 90,90, 10,90, 10,10
{const}	aptPentagon	POLYLINE 50,2, 98,35, 79,90, 21,90, 2,35, 50,2
{const}	aptHexagon	POLYLINE 50,2, 93,25, 93,75, 50,98, 7,75, 7,25, 50,2
{data}	ppt dq aptPentagon ;*POLYLINE


; default DefWindowProcA handling:
;	WM_CREATE	return 0
;	WM_CLOSE	DestroyWindow
WndProcA: fastcall?.frame = 0
	iterate MSG, WM_CHAR,WM_PAINT,WM_SIZE,WM_LBUTTONDOWN,WM_DESTROY
		cmp edx, MSG
		jz .MSG
	end iterate
.default:
	extrn __imp_DefWindowProcA
	jmp qword [__imp_DefWindowProcA]

.WM_CHAR:
	iterate key, 3,4,5,6,VK_ESCAPE
		if `key > 0xFFFF ; VK_*
			cmp r8w, key
		else
			cmp r8w, `key
		end if
		jz .WM_CHAR.key
	end iterate
.WM_SIZE:
	enter 32, 0
	InvalidateRect rcx, 0, TRUE
	jmp .processed
.WM_CHAR.3:
	mov [ppt], aptTriangle
	jmp .WM_SIZE
.WM_CHAR.4:
	mov [ppt], aptSquare
	jmp .WM_SIZE
.WM_CHAR.5:
	mov [ppt], aptPentagon
	jmp .WM_SIZE
.WM_CHAR.6:
	mov [ppt], aptHexagon
	jmp .WM_SIZE
.WM_CHAR.VK_ESCAPE: ; respect window message heirarchy
	enter 32, 0
	DestroyWindow rcx
.processed:
	xor eax, eax
	leave
	retn

.WM_DESTROY: ; n/a, n/a ; window already closed
	enter 32, 0
	PostQuitMessage 0
	jmp .processed

.WM_LBUTTONDOWN:
	enter 32, 0
	; undocumented, SC_MOVE or HTCAPTION = SC_DRAGMOVE = F012
	SendMessageA rcx, WM_SYSCOMMAND, SC_MOVE or HTCAPTION, 0
	jmp .processed

; We can split any messages off to use their own scope ...
WndProcA.WM_PAINT: fastcall?.frame = 0
	virtual at rbp - .local
		.ps	PAINTSTRUCT
			align.assume rbp, 16
			align 16
		.local := $ - $$
			rq 2
		.hWnd	dq ?
		.hDC	dq ?
		.rc	RECT
		assert $ - .hWnd < 33 ; shadow limit
	end virtual
	enter .frame + .local, 0
	mov [.hWnd], rcx
	BeginPaint [.hWnd], addr .ps
	mov [.hDC], rax
	GetClientRect [.hWnd], addr .rc
	SetMapMode [.hDC], MM_ANISOTROPIC
	SetWindowExtEx [.hDC], 100, 100, 0
	SetViewportExtEx [.hDC], [.rc.right], [.rc.bottom], 0
	mov rdx, [ppt]
	mov r8d, [rdx + POLYLINE.POINTS]
	Polyline [.hDC], rdx, r8
	EndPaint [.hWnd], addr .ps
	xor eax, eax
	leave
	retn
	.frame := fastcall?.frame


;-------------------------------------------------------------------------------
CursorMonitorA: fastcall?.frame = 0
{data}	.mi MONITORINFOEXA cbSize: sizeof .mi ; return product is global data
	virtual at rbp + 16
		.hMonitor	dq ? ; HMONITOR
		.pt		POINT
		assert $ - $$ < 33 ; shadow use only
	end virtual
	enter .frame, 0
	GetCursorPos addr .pt
	; note: point structure data is pass in register
	MonitorFromPoint qword [.pt], dword MONITOR_DEFAULTTONEAREST
	xchg rcx, rax
	GetMonitorInfoA rcx, dword .mi
	leave
	retn
	.frame := fastcall?.frame

;-------------------------------------------------------------------------------
WinMainCRTStartup: fastcall?.frame = 0
	sub rsp, .frame - 8*5 ; reuse system shadow, no return
	mov [.msg.wParam], 1 ; EXIT_FAILURE

; square window, 2/3 of screen, centered on mouse monitor

{bss}	.rc RECT
	call CursorMonitorA
	CopyRect addr .rc, addr CursorMonitorA.mi.rcMonitor
	mov ebx, [.rc.right]
	mov ecx, [.rc.bottom]
	sub ebx, [.rc.left]	; width
	sub ecx, [.rc.top]	; height
	mov eax, ecx
	cmp ebx, ecx
	cmovc eax, ebx ; min size

	mov edx, 0xAAAA_AAAB ; 2/3
	mul edx

	sub ebx, edx
	sub ecx, edx
	sar ebx, 1
	sar ecx, 1
	add [.rc.left], ebx
	add [.rc.top], ecx
	sub [.rc.right], ebx
	sub [.rc.bottom], ecx

.xstyle = WS_EX_TOOLWINDOW ;or WS_EX_TOPMOST
.style = WS_POPUP or WS_VISIBLE or WS_SYSMENU or WS_SIZEBOX or WS_CAPTION

	AdjustWindowRect addr .rc, dword .style, 0, dword .xstyle
	mov ebx, [.rc.right]
	mov ecx, [.rc.bottom]
	sub ebx, [.rc.left]
	sub ecx, [.rc.top]
	mov [.rc.right], ebx	; width
	mov [.rc.bottom], ecx	; height

{data}	.clsName db "bitRAKE",0
{data}	.wcex WNDCLASSEX cbSize: sizeof .wcex,\
		lpfnWndProc: WndProcA,\
		hInstance: __ImageBase,\
		lpszClassName: .clsName,\
		hbrBackground: 1+COLOR_WINDOW
	RegisterClassExA dword .wcex
	movzx edx, ax ; ATOM
{const}	.title db "GDI: Polylines",0
	CreateWindowExA .xstyle, rdx, dword .title, .style,\
		[.rc.left], [.rc.top], [.rc.right], [.rc.bottom],\
		0, 0, __ImageBase, 0
{bss}	.hWnd dq ?
	mov [.hWnd], rax
	jmp @F
{bss}	.msg MSG
.message_loop:
	TranslateMessage dword .msg
	DispatchMessageA dword .msg
@@:	GetMessageA dword .msg, 0, 0, 0, 0
	test eax, eax ; BOOL or -1
	jg .message_loop
.Fatal:
	ExitProcess [.msg.wParam]
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
