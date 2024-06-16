; http://msdn.microsoft.com/en-us/library/bb761374.aspx
include '..\windows.g'
include '..\controls.h'

extrn 'DialogProcW.WM_CLOSE' as IPAddressDlgProc.WM_CLOSE

public IPAddressDlgProc
:IPAddressDlgProc:
	cmp edx, WM_CLOSE
	jz .WM_CLOSE
	cmp edx, WM_INITDIALOG
	jz .WM_INITDIALOG
	xor eax, eax
	retn

.WM_INITDIALOG:
	enter .frame, 0
	label .hDialog		at rbp+16 ; use shadow space
	label .hIPAddress	at rbp+24
	mov [.hDialog], rcx ; hDialog
	SetWindowTextW rcx, r9 ; parent has given name

{const:8} .iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_INTERNET_CLASSES
	InitCommonControlsEx dword .iccx
	test eax, eax ; BOOL
	jz @F

	; Create the IP Address control

	CreateWindowExW 0, W "SysIPAddress32", 0, WS_CHILD or WS_VISIBLE,\
		20, 20, 180, 24, [.hDialog], IDC_IPADDRESS, __ImageBase, 0
	mov [.hIPAddress], rax

	; TODO:

	GetStockObject DEFAULT_GUI_FONT
	SendMessageW [.hIPAddress], WM_SETFONT, rax, 0

	xor eax, eax
@@:	leave
	retn
