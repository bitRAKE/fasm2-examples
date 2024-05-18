include 'AppWindow.g'

WIDTH	:= 512 ; [biHeader.biWidth]
HEIGHT	:= 512 ; [biHeader.biHeight]

{bss} align 64
{bss} label dib_data:(WIDTH * HEIGHT) shl 2
{bss} rb sizeof dib_data

{data} align 16
{data} bitmap_info: ; BITMAPINFO
{data} biHeader BITMAPINFOHEADER \
	biSize:		sizeof BITMAPINFOHEADER,\
	biWidth:	WIDTH,\
	biHeight:	HEIGHT,\
	biPlanes:	1,\
	biBitCount:	32,\; DWORD per pixel
	biCompression:	BI_RGB


; default DefWindowProcA handling:
;	WM_CREATE	return 0
;	WM_CLOSE	DestroyWindow
WndProcA: fastcall?.frame = 0
	iterate MSG, WM_ERASEBKGND,WM_LBUTTONDOWN,WM_RBUTTONUP,WM_KEYDOWN,WM_SYSCOMMAND,WM_DESTROY
		cmp edx, MSG
		jz .MSG
	end iterate
.default:
	extrn __imp_DefWindowProcA
	jmp qword [__imp_DefWindowProcA]

.WM_SYSCOMMAND:
	cmp r8d, ID_ABOUT
	jnz .default
	enter 32, 0
	{data} .caption db "About ...",0
	{data} .text db "Using GDI to create an immediate type UI.",0
	{data} align 8
	MessageBoxA rcx, dword .text, dword .caption, MB_OK
	xor eax, eax
	leave
	retn

.WM_KEYDOWN:
	cmp r8d, VK_ESCAPE
	jnz .default
	; respect window message heirarchy
	enter 32, 0
	DestroyWindow rcx
	xor eax, eax
	leave
	retn

.WM_DESTROY: ; n/a, n/a ; window already closed
	enter 32, 0
	PostQuitMessage 0
	xor eax, eax
	leave
	retn


.WM_LBUTTONDOWN:
	enter 32, 0

	; Windows shows the cursor during move operation,
	; but doesn't change cursor. TODO: set cursor to hand?

	; undocumented, SC_MOVE or HTCAPTION = SC_DRAGMOVE = F012
	SendMessageA rcx, WM_SYSCOMMAND, SC_MOVE or HTCAPTION, 0

	xor eax, eax
	leave
	retn


.WM_ERASEBKGND: ; hDC, n/a
	push rax ; n/a
	xchg rcx, r8 ; hDC
	xor edx, edx
	xor r8, r8
	mov r9d, [biHeader.biWidth]
	push rdx ; DIB_RGB_COLORS
	push bitmap_info ; #32#
	push dib_data ; #32#
	push qword [biHeader.biWidth]
	push rdx
	push rdx
	push rdx
	push qword [biHeader.biHeight]
	sub esp, 8*4 ; #32#
	SetDIBitsToDevice
	add esp, 8*13 ; #32#
	; only return non-zero if lines were copied
	test eax, eax
	setnz al
	movzx eax, al
	retn
	.frame := fastcall?.frame

; We can split any messages off to use their own scope ...
WndProcA.WM_RBUTTONUP: fastcall?.frame = 0
	enter .frame, 0
	virtual at rbp+16 ; use shadow space
		.hWnd		dq ?
;		.hMenu		dq ?
		.pt		POINT
		assert $-$$ < 33
	end virtual
; notes: WM_RBUTTONUP mouse coordinates are screen relative
;	WM_RBUTTONDOWN brings window forward?
;	SetForegroundWindow [.hWnd]
	; preserve fastcall parameter(s)
	mov [.hWnd], rcx
	GetCursorPos addr .pt ; client relative coordinates
	TrackPopupMenu [WinMainCRTStartup.hSysMenu],\
		TPM_RIGHTBUTTON or TPM_RETURNCMD,\
		[.pt.x], [.pt.y], 0, [.hWnd], 0
	xchg ecx, eax
	jrcxz .no_sysmenu
	; forward system command for default processing
	mov r8d, ecx
	mov r9d, [.pt.y + 2] ; high word, zero high dword
	mov r9w, word [.pt.x] ; just low word
	SendMessageA [.hWnd], WM_SYSCOMMAND, r8, r9
.no_sysmenu:
	xor eax, eax ; handled
	leave
	retn
	.frame := fastcall?.frame

;SC_SEPARATOR


;-------------------------------------------------------------------------------
; linker expects this default name for entry point
WinMainCRTStartup: fastcall?.frame = 0
	sub rsp, .frame - 8*5 ; reuse system shadow, no return
	mov [.msg.wParam], 1 ; EXIT_FAILURE

	; just a red frame - so we can find the window:

	.COLOR := 0xFFFF0000

	mov ecx, WIDTH/2
@@:	mov dword [dib_data + (rcx-1)*8], .COLOR
	mov dword [dib_data + (rcx-1)*8 + (HEIGHT-1)*4*WIDTH], .COLOR
	loop @B
	mov ecx, HEIGHT/2
@@:	imul eax, ecx, 8*WIDTH ; line stride
	mov dword [dib_data + rax - 4], .COLOR
	mov dword [dib_data + rax - 4*WIDTH], .COLOR
	loop @B

{data}	.szClassNameA db "bitRAKE",0
{data}	.wndclass WNDCLASS 0,WndProcA,0,0,__ImageBase,0,0,0,0,.szClassNameA

	RegisterClassA dword .wndclass
	movzx edx, ax ; ATOM

.XSTYLE = WS_EX_APPWINDOW or WS_EX_LAYERED
.STYLE = WS_POPUP or WS_VISIBLE or WS_SYSMENU
	CreateWindowExA .XSTYLE, rdx, 0, .STYLE,\
		dword CW_USEDEFAULT, dword CW_USEDEFAULT, dword WIDTH, dword HEIGHT,\
		0, 0, __ImageBase, 0
{bss}	.hWnd dq ?
	mov [.hWnd], rax

{data}	.bb DWM_BLURBEHIND fEnable: TRUE, dwFlags: DWM_BB_ENABLE
	DwmEnableBlurBehindWindow [.hWnd], addr .bb

	SetLayeredWindowAttributes [.hWnd], 0, 200, LWA_ALPHA

; configure system menu
	GetSystemMenu [.hWnd], 0
	test rax, rax
	jz .Fatal
{bss}	.hSysMenu dq ?
	mov [.hSysMenu], rax

{data}	_XSysCommands dw SC_SIZE,SC_MOVE,SC_MINIMIZE,SC_MAXIMIZE,SC_RESTORE,0

	lea esi, [_XSysCommands]
@@:	lodsw
	movzx edx,ax
	RemoveMenu [.hSysMenu],rdx,MF_BYCOMMAND
	cmp byte [rsi], 0
	jnz @B

ID_ABOUT := 100h
{data}	_ABOUT db "About ...",0
{data}	align 8
;	InsertMenuA [.hSysMenu], 0, MF_BYPOSITION or MF_SEPARATOR, 0, 0
	InsertMenuA [.hSysMenu], 0, MF_BYPOSITION or MF_STRING, ID_ABOUT, _ABOUT
;	InsertMenuA [.hSysMenu], 0, MF_BYPOSITION or MF_SEPARATOR, 0, 0

	jmp .peek
{bss}	.msg MSG
.message_loop:
	TranslateMessage dword .msg
	DispatchMessageA dword .msg
.peek:	PeekMessageA dword .msg, 0, 0, 0, PM_REMOVE
	test eax, eax ; BOOL
	jnz .message_loop

	Sleep 1

;	InvalidateRect [.hWnd], 0, 1 ; use WM_ERASEBKGND handler

	cmp [.msg.message], WM_QUIT
	jnz .peek
.Fatal:
	ExitProcess [.msg.wParam]
	.frame := fastcall?.frame

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
	db 'dwmapi.lib',10
end virtual
