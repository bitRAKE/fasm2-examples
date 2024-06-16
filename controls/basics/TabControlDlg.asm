; http://msdn.microsoft.com/en-us/library/bb760548.aspx
include '..\windows.g'
include '..\controls.h'

extrn 'DialogProcW.WM_CLOSE' as TabControlDlgProc.WM_CLOSE
extrn 'FirstChild2ClientW.WM_SIZE' as TabControlDlgProc.WM_SIZE

public TabControlDlgProc
:TabControlDlgProc:
	iterate message, WM_SIZE,WM_CLOSE,WM_INITDIALOG
		cmp edx, message
		jz .message
	end iterate
	xor eax, eax
	retn

.WM_INITDIALOG:
	virtual at rbp + 16 ; only shadow space
		.hDialog	dq ?
		.hTab		dq ?
		.rc		RECT
	end virtual
	enter .frame, 0
	mov [.hDialog], rcx
	SetWindowTextW rcx, r9 ; parent has given name

{const:8} .iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_TAB_CLASSES
	InitCommonControlsEx .iccx
	test eax, eax ; BOOL
	jz @F

	; Create the Tab control to fill client area.
	GetClientRect [.hDialog], addr .rc
	CreateWindowExW 0, W "SysTabControl32", 0, WS_CHILD or WS_VISIBLE or TCS_FIXEDWIDTH,\
		[.rc.left], [.rc.top], [.rc.right], [.rc.bottom],\
		[.hDialog], IDC_TAB, __ImageBase, 0
	test rax, rax
	jz @F
	mov [.hTab], rax

	GetStockObject DEFAULT_GUI_FONT
	SendMessageW [.hTab], WM_SETFONT, rax, 0

{data:8} .ti TC_ITEM mask: TCIF_TEXT

	iterate text,\
		"First Page",\
		"Second Page",\
		"Third Page",\
		"Fourth Page",\
		"Fifth Page"

		{const:2} .% du text
		{const:2} .%.end du 0
		mov [.ti.pszText], .%
		mov [.ti.cchTextMax], (.%.end - .%) shr 1
		SendMessageW [.hTab], TCM_INSERTITEMW, %-1, addr .ti
	end iterate
@@:	leave
	xor eax, eax
	retn
