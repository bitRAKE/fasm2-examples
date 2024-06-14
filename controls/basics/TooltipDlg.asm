; http://msdn.microsoft.com/en-us/library/bb760246.aspx
include '..\windows.g'
include '..\controls.h'

extrn 'DialogProcW.WM_CLOSE' as TooltipDlgProc.WM_CLOSE

public TooltipDlgProc
:TooltipDlgProc:
	cmp edx, WM_CLOSE
	jz .WM_CLOSE
	cmp edx, WM_INITDIALOG
	jz .WM_INITDIALOG
	xor eax, eax
	retn

.WM_INITDIALOG:
	enter .frame, 0
	label .hDialog:8 at .ti.hwnd ; reuse structure field
	mov [.ti.hwnd], rcx ; hDialog
	SetWindowTextW rcx, r9 ; parent has given name

{const}	.iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_WIN95_CLASSES
	InitCommonControlsEx dword .iccx
	test eax, eax ; BOOL
	jz @F

{const}	.BUTTON du "BUTTON",0
{const}	.txt du "Tooltip Target",0
	CreateWindowExW 0, dword .BUTTON, dword .txt, WS_CHILD or WS_VISIBLE,\
		20, 20, 120, 40, [.hDialog], IDC_BUTTON1, __ImageBase, 0
	test rax, rax
	jz @F
	mov [.ti.uId], rax

	; Create a tooltip
	; A tooltip control should not have the WS_CHILD style, nor should it
	; have an id, otherwise its behavior will be adversely affected.
{const}	.tooltips_class32 du "tooltips_class32",0
	CreateWindowExW 0, dword .tooltips_class32, 0, TTS_ALWAYSTIP,\
		0, 0, 0, 0, [.hDialog], 0, __ImageBase, 0
	test rax, rax
	jz @F

{const}	.tip du "A button by another name is still just a button.",0
{data}	.ti TOOLINFO cbSize: sizeof .ti,\
		uFlags: TTF_IDISHWND or TTF_SUBCLASS,\
		lpszText: .tip

	; Associate the tooltip with the button control.
	SendMessageW rax, TTM_ADDTOOLW, 0, addr .ti
	mov eax, 1
@@:	leave
	retn
