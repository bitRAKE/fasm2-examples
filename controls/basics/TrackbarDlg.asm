; http://msdn.microsoft.com/en-us/library/bb760145.aspx
include '..\windows.g'
include '..\controls.h'

extrn 'DialogProcW.WM_CLOSE' as TrackbarDlgProc.WM_CLOSE

public TrackbarDlgProc
:TrackbarDlgProc:
	cmp edx, WM_CLOSE
	jz .WM_CLOSE
	cmp edx, WM_INITDIALOG
	jz .WM_INITDIALOG
	xor eax, eax
	retn

.WM_INITDIALOG:
	label .hDialog:8	at rbp + 16 ; only shadow space
	label .hTrackbar:8	at rbp + 24
	enter .frame, 0
	mov [.hDialog], rcx
	SetWindowTextW rcx, r9 ; parent has given name

{const:8} .iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_WIN95_CLASSES
	InitCommonControlsEx dword .iccx
	test eax, eax ; BOOL
	jz @F

	CreateWindowExW 0, W "msctls_trackbar32", 0, WS_CHILD or WS_VISIBLE\
		or TBS_AUTOTICKS or TBS_ENABLESELRANGE,\
		20, 20, 250, 20, [.hDialog], IDC_TRACKBAR, __ImageBase, 0
	test rax, rax ; hTrackbar
	jz @F
	mov [.hTrackbar], rax

	; Set Trackbar Configuration:
	SendMessageW [.hTrackbar], TBM_SETRANGE, 0, 0x0014_0000
	SendMessageW [.hTrackbar], TBM_SETPAGESIZE, 0, 4
	SendMessageW [.hTrackbar], TBM_SETSEL, FALSE, 0x000D_0005        
	SendMessageW [.hTrackbar], TBM_SETPOS, TRUE, 0x0003
	SetFocus [.hTrackbar]

	xor eax, eax
@@:	leave
	retn
