include 'windowApp.g'
WIDTH	:= 512 ; [biHeader.biWidth]
HEIGHT	:= 512 ; [biHeader.biHeight]

~ align 64
~ label dib_data:(WIDTH * HEIGHT) shl 2
~ rb sizeof dib_data

!align 16
!bitmap_info: ; BITMAPINFO
!biHeader BITMAPINFOHEADER \
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
	iterate MSG, WM_ERASEBKGND,WM_KEYDOWN,WM_NCHITTEST,WM_DESTROY
		cmp edx, MSG
		jz .MSG
	end iterate
.default:
	extrn __imp_DefWindowProcA
	jmp qword [__imp_DefWindowProcA]

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

.WM_NCHITTEST: ; n/a, {s16 X, s16 Y} cursor screen coordinates
	enter 32, 0
	DefWindowProcA rcx, rdx, r8, r9
	test eax, eax
	jle @F
	; all valid window positions are caption-like (move window)
	; Windows sets the cursor to arrow
	mov eax, 2 ; HTCAPTION
@@:	leave
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



public WinMain as 'WinMainCRTStartup' ; linker expects this default name
WinMain: fastcall?.frame = 0
	sub rsp, .frame - 8*5 ; reuse system shadow, no return
	SetCursor 0

	; just a red frame - so we can find the window:

	mov ecx, WIDTH
@@:	mov dword [dib_data + (rcx-1)*4], 0xFFFF0000
	mov dword [dib_data + (rcx-1)*4 + (HEIGHT-1)*4*WIDTH], 0xFFFF0000
	loop @B
	mov ecx, HEIGHT
@@:	imul eax, ecx, 4*WIDTH ; line stride
	mov dword [dib_data + rax - 4], 0xFFFF0000
	mov dword [dib_data + rax - 4*WIDTH], 0xFFFF0000
	loop @B

!	.szClassNameA db "bitRAKE",0
!	.wndclass WNDCLASS 0,WndProcA,0,0,__ImageBase,0,0,0,0,.szClassNameA

	RegisterClassA dword .wndclass
	movzx edx, ax ; ATOM
	CreateWindowExA WS_EX_APPWINDOW, rdx, 0,\
		WS_POPUP or WS_VISIBLE or WS_SYSMENU,\
		dword 0, dword 0, dword WIDTH, dword HEIGHT,\
		0, 0, hInstance, 0
~	.hWnd dq ?
	mov [.hWnd], rax

!	.bb DWM_BLURBEHIND fEnable: TRUE, dwFlags: DWM_BB_ENABLE
	DwmEnableBlurBehindWindow [.hWnd], addr .bb

	jmp .peek
~	.msg MSG
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
	ExitProcess [.msg.wParam]
	.frame := fastcall?.frame
