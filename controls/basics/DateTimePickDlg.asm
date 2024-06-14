; http://msdn.microsoft.com/en-us/library/bb761727.aspx
include '..\windows.g'
include '..\controls.h'

extrn 'DialogProcW.WM_CLOSE' as DateTimePickDlgProc.WM_CLOSE

public DateTimePickDlgProc
:DateTimePickDlgProc:
	cmp edx, WM_CLOSE
	jz .WM_CLOSE
	cmp edx, WM_INITDIALOG
	jnz @0F
	label .hDialog:8 at rbp + 16 ; only shadow space
	enter .frame, 0
	mov [.hDialog], rcx
	SetWindowTextW rcx, r9 ; parent has given name

{const}	.iccx INITCOMMONCONTROLSEX dwSize: sizeof .iccx, dwICC: ICC_DATE_CLASSES
	InitCommonControlsEx dword .iccx
	test eax, eax ; BOOL
	jz @F

{const}	.SysDateTimePick32 du "SysDateTimePick32",0
	CreateWindowExW 0, dword .SysDateTimePick32, 0, WS_CHILD or WS_VISIBLE,\
		20, 20, 150, 30, [.hDialog], IDC_DATETIMEPICK, __ImageBase, 0
@@:	leave
@0:	xor eax, eax
	retn
