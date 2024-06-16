; http://msdn.microsoft.com/en-us/library/bb760818.aspx
include '..\windows.g'
include '..\controls.h'

extrn 'DialogProcW.WM_CLOSE' as ProgressDlgProc.WM_CLOSE

public ProgressDlgProc
:ProgressDlgProc:
	cmp edx, WM_CLOSE
	jz .WM_CLOSE
	cmp edx, WM_INITDIALOG
	jz .WM_INITDIALOG
	xor eax, eax
	retn

.WM_INITDIALOG:
	label .hDialog:8 at rbp + 16 ; only shadow space
	enter .frame, 0
	mov [.hDialog], rcx
	SetWindowTextW rcx, r9 ; parent has given name

{const:8} .iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_PROGRESS_CLASS
	InitCommonControlsEx dword .iccx
	test eax, eax ; BOOL
	jz @F
	CreateWindowExW 0, W "msctls_progress32", 0, WS_CHILD or WS_VISIBLE,\
		20, 20, 250, 20, [.hDialog], IDC_PROGRESSBAR, __ImageBase, 0
	test rax, rax
	jz @F
	; Set the progress bar position to half-way.
	SendMessageW rax, PBM_SETPOS, 50, 0
	mov eax, 1
@@:	leave
	retn
